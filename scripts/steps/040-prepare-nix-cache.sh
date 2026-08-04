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

    local ro_values
    local rw_values
    ro_values="$(read_r2_terraform_outputs ro)"
    rw_values="$(read_r2_terraform_outputs rw)"

    local ro_bucket_name
    local ro_s3_endpoint
    local ro_access_key_id
    local ro_secret_access_key
    IFS=$'\t' read -r \
        ro_bucket_name \
        ro_s3_endpoint \
        ro_access_key_id \
        ro_secret_access_key \
        <<<"${ro_values}"

    local rw_bucket_name
    local rw_s3_endpoint
    local rw_access_key_id
    local rw_secret_access_key
    IFS=$'\t' read -r \
        rw_bucket_name \
        rw_s3_endpoint \
        rw_access_key_id \
        rw_secret_access_key \
        <<<"${rw_values}"

    [[ "${ro_bucket_name}" == "${rw_bucket_name}" ]]
    [[ "${ro_s3_endpoint}" == "${rw_s3_endpoint}" ]]

    local cache_url
    cache_url="s3://${ro_bucket_name}?endpoint=${ro_s3_endpoint#https://}&scheme=https&region=auto&priority=30"

    local ro_credentials
    local rw_credentials
    ro_credentials="$(mktemp)"
    rw_credentials="$(mktemp)"
    trap 'rm -f -- "${ro_credentials}" "${rw_credentials}"' EXIT
    umask 077

    printf \
        '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
        "${ro_access_key_id}" \
        "${ro_secret_access_key}" \
        >"${ro_credentials}"

    printf \
        '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
        "${rw_access_key_id}" \
        "${rw_secret_access_key}" \
        >"${rw_credentials}"

    unset ro_access_key_id ro_secret_access_key ro_values
    unset rw_access_key_id rw_secret_access_key rw_values

    local root_nix='/nix/var/nix/profiles/default/bin/nix'
    [[ -x "${root_nix}" ]] || return 1

    # Nix creates nix-cache-info when a binary cache is opened for the first
    # time. Initialize it with the write credential before persisting only the
    # read-only credential for normal substitution.
    if ! sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${rw_credentials}" \
        "${root_nix}" store info \
        --store "${cache_url}"; then
        if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
            touch "${cache_disable_file}"
            printf 'R2 Nix cache is unavailable; continuing the CI build without it.\n' >&2
            return 0
        fi

        return 1
    fi

    sudo install -d -m 700 "${credentials%/*}"
    sudo install -m 600 "${ro_credentials}" "${credentials}"

    case "${system}" in
    aarch64-darwin)
        sudo launchctl kickstart -k system/org.nixos.nix-daemon
        ;;
    x86_64-linux)
        sudo systemctl restart nix-daemon.service
        ;;
    *) return 1 ;;
    esac

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
