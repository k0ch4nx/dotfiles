#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function find_secret() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    local name="$1"
    local secret_file="${DOTFILES_DIR}/secrets/${name}.age"

    if [[ ! -r "${secret_file}" ]]; then
        printf 'Expected the canonical secret at %s.\n' "${secret_file}" >&2
        return 1
    fi

    printf '%s' "${secret_file}"
)

function find_yubikey_identity() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    local identity_file="${DOTFILES_DIR}/secrets/yubikey-identity.txt"

    if [[ ! -r "${identity_file}" ]]; then
        printf 'Expected the tracked YubiKey age identity at %s.\n' "${identity_file}" >&2
        return 1
    fi

    printf '%s' "${identity_file}"
)

function find_rage() (
    set +x

    if command -v rage >/dev/null 2>&1; then
        command -v rage
        return 0
    fi

    local rage
    rage="$(
        nix build \
            --no-link \
            --print-out-paths \
            'nixpkgs#rage^out'
    )/bin/rage"

    [[ -x "${rage}" ]]
    printf '%s' "${rage}"
)

function find_age_plugin_yubikey() (
    set +x

    local candidate
    for candidate in age-plugin-yubikey age-plugin-yubikey.exe; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            command -v "${candidate}"
            return 0
        fi
    done

    local plugin
    plugin="$(
        nix build \
            --no-link \
            --print-out-paths \
            'nixpkgs#age-plugin-yubikey^out'
    )/bin/age-plugin-yubikey"

    [[ -x "${plugin}" ]]
    printf '%s' "${plugin}"
)

function decrypt_secret() (
    set +x

    local secret_file="$1"
    local identity_file="$2"
    local rage="$3"
    local age_plugin_yubikey="$4"

    PATH="${age_plugin_yubikey%/*}:${PATH}" \
        "${rage}" \
        --decrypt \
        --identity "${identity_file}" \
        "${secret_file}"
)

function read_hcp_terraform_token() (
    set +x

    if [[ -n "${TF_TOKEN_app_terraform_io:-}" ]]; then
        printf '%s' "${TF_TOKEN_app_terraform_io}"
        return 0
    fi

    decrypt_secret \
        "$(find_secret hcp-terraform-token)" \
        "$(find_yubikey_identity)" \
        "$(find_rage)" \
        "$(find_age_plugin_yubikey)"
)

function read_nix_cache_private_key() (
    set +x

    if [[ -n "${NIX_CACHE_PRIVATE_KEY:-}" ]]; then
        printf '%s' "${NIX_CACHE_PRIVATE_KEY}"
        return 0
    fi

    decrypt_secret \
        "$(find_secret nix-cache-local-private-key)" \
        "$(find_yubikey_identity)" \
        "$(find_rage)" \
        "$(find_age_plugin_yubikey)"
)

function terraform_cli() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    local token
    token="$(read_hcp_terraform_token)"

    if [[ -z "${token}" || "${token}" == *$'\n'* || "${token}" == *$'\r'* ]]; then
        printf 'The HCP Terraform token has an invalid value.\n' >&2
        return 1
    fi

    local status=0
    if command -v terraform >/dev/null 2>&1; then
        TF_TOKEN_app_terraform_io="${token}" terraform "$@" || status=$?
    else
        NIXPKGS_ALLOW_UNFREE=1 \
            TF_TOKEN_app_terraform_io="${token}" \
            nix run \
            --impure \
            --accept-flake-config \
            --no-update-lock-file \
            'nixpkgs#terraform' \
            -- \
            "$@" || status=$?
    fi

    unset token
    return "${status}"
)

function main() {
    local restore_xtrace='false'
    if [[ "$-" == *x* ]]; then
        restore_xtrace='true'
        set +x
    fi

    [[ -n "${DOTFILES_DIR:-}" ]]

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        if [[ -z "${TF_TOKEN_app_terraform_io:-}" ]]; then
            printf 'TF_TOKEN_app_terraform_io is required in CI.\n' >&2
            return 1
        fi
    elif [[ -z "${TF_TOKEN_app_terraform_io:-}" || -z "${NIX_CACHE_PRIVATE_KEY:-}" || -z "${GH_TOKEN:-}" ]]; then
        local token_file
        local private_key_file
        local gh_token_file
        local identity_file
        local rage
        local age_plugin_yubikey

        local token="${TF_TOKEN_app_terraform_io:-}"
        local private_key="${NIX_CACHE_PRIVATE_KEY:-}"
        local gh_token="${GH_TOKEN:-}"

        token_file="$(find_secret hcp-terraform-token)"
        private_key_file="$(find_secret nix-cache-local-private-key)"
        if [[ -z "${gh_token}" ]]; then
            gh_token_file="$(find_secret env/gh-token)"
        fi
        identity_file="$(find_yubikey_identity)"
        rage="$(find_rage)"
        age_plugin_yubikey="$(find_age_plugin_yubikey)"

        if [[ -z "${token}" && -z "${private_key}" ]]; then
            token="$(
                decrypt_secret \
                    "${token_file}" \
                    "${identity_file}" \
                    "${rage}" \
                    "${age_plugin_yubikey}"
            )"
            private_key="$(
                decrypt_secret \
                    "${private_key_file}" \
                    "${identity_file}" \
                    "${rage}" \
                    "${age_plugin_yubikey}"
            )"
        elif [[ -z "${token}" ]]; then
            token="$(
                decrypt_secret \
                    "${token_file}" \
                    "${identity_file}" \
                    "${rage}" \
                    "${age_plugin_yubikey}"
            )"
        elif [[ -z "${private_key}" ]]; then
            private_key="$(
                decrypt_secret \
                    "${private_key_file}" \
                    "${identity_file}" \
                    "${rage}" \
                    "${age_plugin_yubikey}"
            )"
        fi

        if [[ -z "${gh_token}" ]]; then
            gh_token="$(
                decrypt_secret \
                    "${gh_token_file}" \
                    "${identity_file}" \
                    "${rage}" \
                    "${age_plugin_yubikey}"
            )"
        fi

        if [[ -z "${token}" || "${token}" == *$'\n'* || "${token}" == *$'\r'* ]]; then
            printf 'The HCP Terraform token has an invalid value.\n' >&2
            return 1
        fi

        if [[ -z "${private_key}" || "${private_key}" == *$'\n'* || "${private_key}" == *$'\r'* ]]; then
            printf 'The Nix cache private key has an invalid value.\n' >&2
            return 1
        fi

        if [[ -z "${gh_token}" || "${gh_token}" == *$'\n'* || "${gh_token}" == *$'\r'* ]]; then
            printf 'The GitHub token has an invalid value.\n' >&2
            return 1
        fi

        TF_TOKEN_app_terraform_io="${token}"
        export TF_TOKEN_app_terraform_io

        NIX_CACHE_PRIVATE_KEY="${private_key}"

        GH_TOKEN="${gh_token}"
        export GH_TOKEN

        unset token private_key gh_token
    fi

    if [[ "${restore_xtrace}" == 'true' ]]; then
        set -x
    fi
}

main
