set -euo pipefail

readonly bucket="${R2_CACHE_BUCKET:-${DEFAULT_R2_CACHE_BUCKET}}"
readonly account_id="${CLOUDFLARE_ACCOUNT_ID:-${DEFAULT_CLOUDFLARE_ACCOUNT_ID}}"
readonly config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly access_key_file="${config_home}/nix-cache/access-key-id"
readonly secret_key_file="${config_home}/nix-cache/secret-access-key"
readonly private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-${config_home}/nix-cache/private-key}"
readonly dotfiles_dir="${DOTFILES_DIR:-${PWD}}"
readonly cache="s3://${bucket}?endpoint=${account_id}.r2.cloudflarestorage.com&scheme=https&region=auto"
closure_file=""

function default_target() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        printf 'path:%s#darwinConfigurations.macbook-pro.config.system.build.toplevel\n' "${dotfiles_dir}"
    elif [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease; then
        printf 'path:%s#homeConfigurations."k0ch4nx@ubuntu-wsl".activationPackage\n' "${dotfiles_dir}"
    else
        printf 'Unsupported local platform for cache-push.\n' >&2
        exit 1
    fi
}

function read_credential() {
    local file="$1"
    local label="$2"
    local value

    if [[ ! -r "${file}" ]]; then
        printf '%s is not readable: %s\n' "${label}" "${file}" >&2
        exit 1
    fi

    value="$(<"${file}")"

    if [[ -z "${value}" ]] || [[ "${value}" == *$'\n'* ]]; then
        printf '%s must contain exactly one non-empty value.\n' "${label}" >&2
        exit 1
    fi

    printf '%s' "${value}"
}

function cleanup() {
    if [[ -n "${closure_file}" ]]; then
        rm -f "${closure_file}"
    fi
}

trap cleanup EXIT

access_key_id="${R2_ACCESS_KEY_ID:-}"
secret_access_key="${R2_SECRET_ACCESS_KEY:-}"

if [[ -n "${access_key_id}" && -z "${secret_access_key}" ]] ||
    [[ -z "${access_key_id}" && -n "${secret_access_key}" ]]; then
    printf 'R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY must be provided together.\n' >&2
    exit 1
fi

if [[ -z "${access_key_id}" ]]; then
    access_key_id="$(read_credential "${access_key_file}" 'R2 access key ID')"
    secret_access_key="$(read_credential "${secret_key_file}" 'R2 secret access key')"
fi

if [[ ! -r "${private_key_file}" ]]; then
    printf 'Nix cache private key is not readable: %s\n' "${private_key_file}" >&2
    exit 1
fi

if [[ ! -f "${dotfiles_dir}/flake.nix" ]]; then
    printf 'DOTFILES_DIR does not contain flake.nix: %s\n' "${dotfiles_dir}" >&2
    exit 1
fi

if (( $# > 1 )); then
    printf 'Usage: cache-push [flake-installable]\n' >&2
    exit 1
fi

target="${1:-${NIX_CACHE_TARGET:-}}"
if [[ -z "${target}" ]]; then
    target="$(default_target)"
fi

toplevel="$({
    nix build \
        --extra-experimental-features 'nix-command flakes' \
        --impure \
        --no-link \
        --no-update-lock-file \
        --print-out-paths \
        "${target}"
})"

if [[ "${toplevel}" != /nix/store/* ]]; then
    printf 'The local build returned an unexpected store path.\n' >&2
    exit 1
fi

closure_file="$(mktemp)"
nix \
    --extra-experimental-features 'nix-command flakes' \
    path-info \
    --recursive "${toplevel}" >"${closure_file}"

nix \
    --extra-experimental-features 'nix-command flakes' \
    store sign \
    --key-file "${private_key_file}" \
    --stdin <"${closure_file}"

if [[ "$(uname -s)" == "Darwin" ]]; then
    readonly root_nix="/nix/var/nix/profiles/default/bin/nix"
    [[ -x "${root_nix}" ]] || exit 1

    # The caller can read the closure list; only Nix store access requires root.
    # shellcheck disable=SC2024
    AWS_ACCESS_KEY_ID="${access_key_id}" \
        AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
        sudo --preserve-env=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
        "${root_nix}" \
        --extra-experimental-features 'nix-command flakes' \
        copy \
        --to "${cache}" \
        --stdin <"${closure_file}"
else
    AWS_ACCESS_KEY_ID="${access_key_id}" \
        AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
        nix \
        --extra-experimental-features 'nix-command flakes' \
        copy \
        --to "${cache}" \
        --stdin <"${closure_file}"
fi
