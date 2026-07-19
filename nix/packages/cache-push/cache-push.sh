set -euo pipefail

readonly bucket="${R2_CACHE_BUCKET:-dotfiles-nix-cache}"
readonly account_id="${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID is required}"
readonly credentials_file="${R2_WRITE_CREDENTIALS_FILE:-/run/agenix/r2-local-write-credentials}"
readonly private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-/run/agenix/nix-cache-local-private-key}"
readonly dotfiles_dir="${DOTFILES_DIR:-${PWD}}"
readonly cache="s3://${bucket}?endpoint=${account_id}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=nix-r2-write"
closure_file=""

function cleanup() {
    if [[ -n "${closure_file}" ]]; then
        rm -f "${closure_file}"
    fi
}

trap cleanup EXIT

if [[ ! -r "${credentials_file}" ]]; then
    printf 'R2 write credentials are not readable: %s\n' "${credentials_file}" >&2
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

export AWS_SHARED_CREDENTIALS_FILE="${credentials_file}"

toplevel="$({
    nix build \
        --extra-experimental-features 'nix-command flakes' \
        --impure \
        --no-link \
        --no-update-lock-file \
        --print-out-paths \
        "path:${dotfiles_dir}#darwinConfigurations.macbook-pro.config.system.build.toplevel"
})"

if [[ "${toplevel}" != /nix/store/* ]]; then
    printf 'The Darwin build returned an unexpected store path.\n' >&2
    exit 1
fi

closure_file="$(mktemp)"
nix path-info --recursive "${toplevel}" >"${closure_file}"

nix store sign \
    --key-file "${private_key_file}" \
    --stdin <"${closure_file}"

nix copy \
    --to "${cache}" \
    --stdin <"${closure_file}"
