#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

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

    local cache_url
    cache_url="$(
        nix eval \
            --impure \
            --raw \
            --expr '(import ./nix/r2-cache.nix).url'
    )"

    [[ "${credentials}" == /* ]]
    [[ "${cache_url}" == s3://* ]]

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

    local access_key_id
    local secret_access_key

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        if [[ -z "${R2_RO_ACCESS_KEY_ID:-}" && -z "${R2_RO_SECRET_ACCESS_KEY:-}" ]]; then
            return 0
        fi

        access_key_id="${R2_RO_ACCESS_KEY_ID:-}"
        secret_access_key="${R2_RO_SECRET_ACCESS_KEY:-}"
    else
        declare -F terraform_cli >/dev/null

        terraform_cli \
            -chdir="${DOTFILES_DIR}/infra/dotfiles" \
            init \
            -input=false \
            -lockfile=readonly

        access_key_id="$(read_terraform_output 'r2_ro_access_key_id' 32)"
        secret_access_key="$(read_terraform_output 'r2_ro_secret_access_key' 64)"
    fi

    [[ "${#access_key_id}" -eq 32 ]]
    [[ "${#secret_access_key}" -eq 64 ]]

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

    unset access_key_id secret_access_key
    unset R2_RO_ACCESS_KEY_ID R2_RO_SECRET_ACCESS_KEY

    case "${system}" in
    aarch64-darwin)
        sudo launchctl \
            kickstart -k system/org.nixos.nix-daemon
        ;;
    x86_64-linux)
        sudo systemctl restart nix-daemon.service
        ;;
    *) return 1 ;;
    esac

    local root_nix='/nix/var/nix/profiles/default/bin/nix'
    [[ -x "${root_nix}" ]] || return 1

    sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${credentials}" \
        "${root_nix}" store info \
        --store "${cache_url}"
)

main
