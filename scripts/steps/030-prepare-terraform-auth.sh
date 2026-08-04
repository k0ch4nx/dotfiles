#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function find_hcp_terraform_token() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    local token_file="${DOTFILES_DIR}/secrets/hcp-terraform-token.age"

    if [[ ! -r "${token_file}" ]]; then
        printf 'Expected the canonical HCP Terraform token at %s.\n' "${token_file}" >&2
        return 1
    fi

    printf '%s' "${token_file}"
)

function find_yubikey_identity() (
    set +x

    [[ -n "${HOME:-}" ]]

    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local identity_file="${AGE_YUBIKEY_IDENTITY_FILE:-${config_home}/age/yubikey-identity.txt}"

    if [[ ! -r "${identity_file}" ]]; then
        printf 'Expected the YubiKey age identity at %s. Run bootstrap with the YubiKey attached.\n' \
            "${identity_file}" >&2
        return 1
    fi

    printf '%s' "${identity_file}"
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

function read_hcp_terraform_token() (
    set +x

    if [[ -n "${TF_TOKEN_app_terraform_io:-}" ]]; then
        printf '%s' "${TF_TOKEN_app_terraform_io}"
        return 0
    fi

    local token_file
    token_file="$(find_hcp_terraform_token)"

    local identity_file
    identity_file="$(find_yubikey_identity)"

    local rage
    if command -v rage >/dev/null 2>&1; then
        rage="$(command -v rage)"
    else
        rage="$(
            nix build \
                --no-link \
                --print-out-paths \
                'nixpkgs#rage^out'
        )/bin/rage"
    fi

    local age_plugin_yubikey
    age_plugin_yubikey="$(find_age_plugin_yubikey)"

    PATH="${age_plugin_yubikey%/*}:${PATH}" \
        "${rage}" \
        --decrypt \
        --identity "${identity_file}" \
        "${token_file}"
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

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    if [[ -n "${TF_TOKEN_app_terraform_io:-}" ]]; then
        return 0
    fi

    find_hcp_terraform_token >/dev/null
    find_yubikey_identity >/dev/null
    find_age_plugin_yubikey >/dev/null

    # Read token once and export for subsequent steps
    export TF_TOKEN_app_terraform_io
    TF_TOKEN_app_terraform_io="$(read_hcp_terraform_token)"
)

main
