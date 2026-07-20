set -euo pipefail

readonly bucket="${R2_CACHE_BUCKET:-${DEFAULT_R2_CACHE_BUCKET}}"
readonly account_id="${CLOUDFLARE_ACCOUNT_ID:-${DEFAULT_CLOUDFLARE_ACCOUNT_ID}}"
readonly profile="${R2_CACHE_PROFILE:-${DEFAULT_R2_CACHE_PROFILE}}"
readonly config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly credentials_file="${R2_CREDENTIALS_FILE:-${config_home}/nix-cache/credentials}"
readonly private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-${config_home}/nix-cache/private-key}"
readonly dotfiles_dir="${DOTFILES_DIR:-${PWD}}"
readonly cache="s3://${bucket}?endpoint=${account_id}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=${profile}"
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

function cleanup() {
    if [[ -n "${closure_file}" ]]; then
        rm -f "${closure_file}"
    fi
}

trap cleanup EXIT

if [[ ! -r "${credentials_file}" ]]; then
    printf 'R2 credentials are not readable: %s\n' "${credentials_file}" >&2
    exit 1
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

export AWS_SHARED_CREDENTIALS_FILE="${credentials_file}"

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
nix path-info --recursive "${toplevel}" >"${closure_file}"

nix store sign \
    --key-file "${private_key_file}" \
    --stdin <"${closure_file}"

if [[ "$(uname -s)" == "Darwin" ]]; then
    # The caller can read the closure list; only the Nix store paths require root.
    # shellcheck disable=SC2024
    sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE}" \
        "$(command -v nix)" \
        --extra-experimental-features 'nix-command flakes' \
        copy \
        --to "${cache}" \
        --stdin <"${closure_file}"
else
    nix copy \
        --to "${cache}" \
        --stdin <"${closure_file}"
fi
