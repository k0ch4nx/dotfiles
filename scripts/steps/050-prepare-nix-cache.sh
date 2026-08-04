#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    if ! declare -F terraform_cli >/dev/null; then
        # shellcheck disable=SC1091
        source "${DOTFILES_DIR}/scripts/steps/045-prepare-terraform-auth.sh"
    fi

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

    terraform_cli \
        -chdir="${DOTFILES_DIR}/infra/dotfiles" \
        init \
        -input=false \
        -lockfile=readonly

    function read_terraform_output() {
        local output_name="$1"
        local value

        value="$(
            terraform_cli \
                -chdir="${DOTFILES_DIR}/infra/dotfiles" \
                output \
                -raw \
                "${output_name}"
        )"

        if [[ -z "${value}" || "${value}" == *$'\n'* || "${value}" == *$'\r'* ]]; then
            printf 'Terraform output %s has an invalid value.\n' "${output_name}" >&2
            return 1
        fi

        printf '%s' "${value}"
    }

    local bucket_name
    bucket_name="$(read_terraform_output 'bucket_name')"

    if [[ "${bucket_name}" == *['/?&#']* ]]; then
        printf 'Terraform output bucket_name is not a valid S3 bucket name.\n' >&2
        return 1
    fi

    local s3_endpoint
    s3_endpoint="$(read_terraform_output 's3_endpoint')"

    if [[ "${s3_endpoint}" != https://* || "${s3_endpoint#https://}" == */* ]]; then
        printf 'Terraform output s3_endpoint is not a valid HTTPS endpoint.\n' >&2
        return 1
    fi

    local cache_url
    cache_url="s3://${bucket_name}?endpoint=${s3_endpoint#https://}&scheme=https&region=auto&priority=30"

    local access_key_id
    local secret_access_key

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        if [[ -z "${R2_RO_ACCESS_KEY_ID:-}" && -z "${R2_RO_SECRET_ACCESS_KEY:-}" ]]; then
            return 0
        fi

        access_key_id="${R2_RO_ACCESS_KEY_ID:-}"
        secret_access_key="${R2_RO_SECRET_ACCESS_KEY:-}"
    else
        access_key_id="$(read_terraform_output 'r2_ro_access_key_id')"
        secret_access_key="$(read_terraform_output 'r2_ro_secret_access_key')"
    fi

    if [[ "${#access_key_id}" -ne 32 ]]; then
        printf 'The R2 read-only access key ID has an invalid value.\n' >&2
        return 1
    fi

    if [[ "${#secret_access_key}" -ne 64 ]]; then
        printf 'The R2 read-only secret access key has an invalid value.\n' >&2
        return 1
    fi

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
