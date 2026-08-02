#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function find_hcp_terraform_token() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]

    local token_file="${DOTFILES_DIR}/secrets/hcp-terraform-token.age"

    if [[ ! -r "${token_file}" ]]; then
        printf 'Expected the canonical HCP Terraform token at %s.\n' "${token_file}" >&2
        return 1
    fi

    printf '%s' "${token_file}"
)

function terraform_cli() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]
    [[ -n "${DOTFILES_USER:-}" ]]

    local identity="${DOTFILES_DIR}/secrets/hosts/${DOTFILES_HOST}-${DOTFILES_USER}-key.txt"
    [[ -r "${identity}" ]]

    local token_file
    token_file="$(find_hcp_terraform_token)"

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

    local token
    token="$("${rage}" --decrypt --identity "${identity}" "${token_file}")"

    if [[ -z "${token}" || "${token}" == *$'\n'* || "${token}" == *$'\r'* ]]; then
        printf 'The HCP Terraform token has an invalid value.\n' >&2
        return 1
    fi

    local status=0
    if command -v terraform >/dev/null 2>&1; then
        TF_TOKEN_app_terraform_io="${token}" terraform "$@" || status=$?
    else
        TF_TOKEN_app_terraform_io="${token}" \
            nix run \
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

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        return 0
    fi

    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]
    [[ -n "${DOTFILES_USER:-}" ]]
    [[ -r "${DOTFILES_DIR}/secrets/hosts/${DOTFILES_HOST}-${DOTFILES_USER}-key.txt" ]]

    find_hcp_terraform_token >/dev/null
)

main
