#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    function terraform_cli() {
        if command -v terraform >/dev/null 2>&1; then
            terraform "$@"
        else
            nix run \
                --accept-flake-config \
                --no-update-lock-file \
                'nixpkgs#terraform' \
                -- \
                "$@"
        fi
    }

    function read_terraform_output() {
        local output_name="$1"
        local expected_length="$2"
        local value

        value="$(
            terraform_cli \
                -chdir="${DOTFILES_DIR}/infra/dotfiles" \
                output \
                -raw \
                "${output_name}"
        )"

        if [[ "${#value}" -ne "${expected_length}" || "${value}" == *$'\n'* ]]; then
            printf 'Terraform output %s has an invalid value.\n' "${output_name}" >&2
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
    local private_key_file="${NIX_CACHE_PRIVATE_KEY_FILE:-${config_home}/nix-cache/private-key}"
    local cache="s3://${bucket}?endpoint=${account_id}.r2.cloudflarestorage.com&scheme=https&region=auto"

    local access_key_id
    local secret_access_key

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        access_key_id="${R2_RW_ACCESS_KEY_ID:-}"
        secret_access_key="${R2_RW_SECRET_ACCESS_KEY:-}"
    else
        export TF_CLI_CONFIG_FILE="${HOME}/.config/terraform/terraform.tfrc"

        if [[ ! -s "${TF_CLI_CONFIG_FILE}" ]]; then
            printf 'Skipping the local R2 cache upload: run terraform login first.\n' >&2
            return 0
        fi

        terraform_cli \
            -chdir="${DOTFILES_DIR}/infra/dotfiles" \
            init \
            -input=false \
            -lockfile=readonly

        access_key_id="$(read_terraform_output 'r2_rw_access_key_id' 32)"
        secret_access_key="$(read_terraform_output 'r2_rw_secret_access_key' 64)"
    fi

    [[ "${#access_key_id}" -eq 32 ]]
    [[ "${#secret_access_key}" -eq 64 ]]

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
