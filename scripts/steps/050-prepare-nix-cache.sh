#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    # shellcheck disable=SC1091
    source "${DOTFILES_DIR}/scripts/lib/r2-terraform-outputs.sh"

    local system
    system="$(
        nix eval \
            --impure \
            --raw \
            --expr 'builtins.currentSystem'
    )"

    local credentials
    credentials="$(
        nix eval \
            --impure \
            --raw \
            --expr "(import ./nix/r2-cache.nix).systems.\"${system}\".credentialsFile"
    )"

    [[ "${credentials}" == /* ]]

    local cache_disable_file="${NIX_CACHE_DISABLE_FILE:-/tmp/dotfiles-disable-r2-cache}"
    rm -f -- "${cache_disable_file}"

    local r2_values
    r2_values="$(read_r2_terraform_outputs ro)"

    local bucket_name
    local s3_endpoint
    local access_key_id
    local secret_access_key
    IFS=$'\t' read -r \
        bucket_name \
        s3_endpoint \
        access_key_id \
        secret_access_key \
        <<<"${r2_values}"

    local cache_url
    cache_url="s3://${bucket_name}?endpoint=${s3_endpoint#https://}&scheme=https&region=auto&priority=30"

    local temporary_credentials
    temporary_credentials="$(mktemp)"
    trap 'rm -f -- "${temporary_credentials}"' EXIT
    umask 077

    printf \
        '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
        "${access_key_id}" \
        "${secret_access_key}" \
        >"${temporary_credentials}"

    sudo install -d -m 700 "${credentials%/*}"
    sudo install -m 600 "${temporary_credentials}" "${credentials}"

    unset access_key_id secret_access_key r2_values

    case "${system}" in
    aarch64-darwin)
        sudo launchctl kickstart -k system/org.nixos.nix-daemon
        ;;
    x86_64-linux)
        sudo systemctl restart nix-daemon.service
        ;;
    *) return 1 ;;
    esac

    local root_nix='/nix/var/nix/profiles/default/bin/nix'
    [[ -x "${root_nix}" ]] || return 1

    if ! sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${credentials}" \
        "${root_nix}" store info \
        --store "${cache_url}"; then
        if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
            touch "${cache_disable_file}"
            printf 'R2 Nix cache is unavailable; continuing the CI build without it.\n' >&2
            return 0
        fi

        return 1
    fi
)

main
