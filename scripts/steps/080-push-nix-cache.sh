#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    function read_credential() {
        local file="$1"
        local label="$2"
        local value

        if [[ ! -r "${file}" ]]; then
            printf '%s is not readable: %s\n' "${label}" "${file}" >&2
            return 1
        fi

        value="$(<"${file}")"

        if [[ -z "${value}" ]] || [[ "${value}" == *$'\n'* ]]; then
            printf '%s must contain exactly one non-empty value.\n' "${label}" >&2
            return 1
        fi

        printf '%s' "${value}"
    }

    local bucket
    bucket="${R2_CACHE_BUCKET:-$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            'path:.#cacheSettings.bucket'
    )}"

    local account_id
    account_id="${CLOUDFLARE_ACCOUNT_ID:-$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            'path:.#cacheSettings.accountId'
    )}"

    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local access_key_file="${config_home}/nix-cache/access-key-id"
    local secret_key_file="${config_home}/nix-cache/secret-access-key"
    local private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-${config_home}/nix-cache/private-key}"
    local cache="s3://${bucket}?endpoint=${account_id}.r2.cloudflarestorage.com&scheme=https&region=auto"

    local access_key_id="${R2_ACCESS_KEY_ID:-}"
    local secret_access_key="${R2_SECRET_ACCESS_KEY:-}"

    if [[ -n "${access_key_id}" && -z "${secret_access_key}" ]] ||
        [[ -z "${access_key_id}" && -n "${secret_access_key}" ]]; then
        printf 'R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY must be provided together.\n' >&2
        return 1
    fi

    if [[ -z "${access_key_id}" ]]; then
        access_key_id="$(read_credential "${access_key_file}" 'R2 access key ID')"
        secret_access_key="$(read_credential "${secret_key_file}" 'R2 secret access key')"
    fi

    if [[ ! -r "${private_key_file}" ]]; then
        printf 'Nix cache private key is not readable: %s\n' "${private_key_file}" >&2
        return 1
    fi

    local target="${NIX_CACHE_TARGET:-}"
    if [[ -z "${target}" ]]; then
        if [[ "$(uname -s)" == 'Darwin' ]]; then
            target='path:.#configurationBuilds.macbook-pro.system'
        elif [[ -r /proc/sys/kernel/osrelease ]] &&
            grep -qi microsoft /proc/sys/kernel/osrelease; then
            target='path:.#configurationBuilds.ubuntu-wsl.home'
        else
            printf 'Unsupported local platform for cache-push.\n' >&2
            return 1
        fi
    fi

    local toplevel
    toplevel="$(
        nix build \
            --accept-flake-config \
            --impure \
            --no-link \
            --no-update-lock-file \
            --print-out-paths \
            "${target}"
    )"

    [[ "${toplevel}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

    local closure_file=''

    # shellcheck disable=SC2329
    function cleanup() {
        [[ -z "${closure_file}" ]] || rm -f "${closure_file}"
    }

    trap cleanup EXIT

    closure_file="$(mktemp)"

    nix path-info --recursive "${toplevel}" >"${closure_file}"

    nix store sign \
        --key-file "${private_key_file}" \
        --stdin <"${closure_file}"

    if [[ "$(uname -s)" == 'Darwin' ]]; then
        local root_nix='/nix/var/nix/profiles/default/bin/nix'
        [[ -x "${root_nix}" ]] || return 1

        # The caller can read the closure list; only Nix store access requires root.
        # shellcheck disable=SC2024
        AWS_ACCESS_KEY_ID="${access_key_id}" \
            AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
            sudo --preserve-env=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
            "${root_nix}" copy \
            --to "${cache}" \
            --stdin <"${closure_file}"
    else
        AWS_ACCESS_KEY_ID="${access_key_id}" \
            AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
            nix copy \
            --to "${cache}" \
            --stdin <"${closure_file}"
    fi
)

main
