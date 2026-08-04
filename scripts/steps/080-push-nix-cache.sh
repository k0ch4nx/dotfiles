#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    # shellcheck disable=SC1091
    source "${DOTFILES_DIR}/scripts/lib/r2-terraform-outputs.sh"

    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-${config_home}/nix-cache/private-key}"

    if [[ ! -r "${private_key_file}" ]]; then
        printf 'Nix cache private key is not readable: %s\n' "${private_key_file}" >&2
        return 1
    fi

    local bucket
    local s3_endpoint
    local access_key_id
    local secret_access_key
    local cache

    function load_cache_connection() {
        local r2_values
        r2_values="$(read_r2_terraform_outputs rw)"

        IFS=$'\t' read -r \
            bucket \
            s3_endpoint \
            access_key_id \
            secret_access_key \
            <<<"${r2_values}"

        cache="s3://${bucket}?endpoint=${s3_endpoint#https://}&scheme=https&region=auto"
    }

    local max_attempts=1
    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        max_attempts=20
    fi

    local attempt
    local cache_available='false'
    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        load_cache_connection

        if AWS_ACCESS_KEY_ID="${access_key_id}" \
            AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
            nix store info --store "${cache}" >/dev/null 2>&1; then
            cache_available='true'
            break
        fi

        if ((attempt < max_attempts)); then
            printf 'R2 write credentials are not active yet; waiting for Terraform apply (%s/%s).\n' \
                "${attempt}" "${max_attempts}" >&2
            sleep 15
        fi
    done

    if [[ "${cache_available}" != 'true' ]]; then
        printf 'Terraform outputs did not provide usable R2 write credentials.\n' >&2
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
            --option narinfo-cache-positive-ttl 0 \
            --to "${cache}" \
            --stdin <"${closure_file}"
    else
        AWS_ACCESS_KEY_ID="${access_key_id}" \
            AWS_SECRET_ACCESS_KEY="${secret_access_key}" \
            nix copy \
            --option narinfo-cache-positive-ttl 0 \
            --to "${cache}" \
            --stdin <"${closure_file}"
    fi
)

main
