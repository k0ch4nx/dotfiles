#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1
    [[ ! "${DOTFILES_HOST:-}" ]] && exit 1
    [[ ! "${DOTFILES_USER:-}" ]] && exit 1

    local identity_dir="${DOTFILES_DIR}/secrets/hosts"
    local identity_name="${DOTFILES_HOST}-${DOTFILES_USER}"
    local private_key="${identity_dir}/${identity_name}-key.txt"
    local public_key="${identity_dir}/${identity_name}.pub"
    local public_value

    umask 077
    install -d -m 700 "${identity_dir}"

    if [[ ! -f "${private_key}" ]]; then
        nix shell nixpkgs#rage -c rage-keygen -o "${private_key}" >/dev/null
        DOTFILES_FORCE_REKEY=true
        export DOTFILES_FORCE_REKEY
    fi

    public_value="$(nix shell nixpkgs#rage -c rage-keygen -y "${private_key}")"

    if [[ ! -f "${public_key}" ]] || [[ "$(<"${public_key}")" != "${public_value}" ]]; then
        printf '%s\n' "${public_value}" >"${public_key}"
        DOTFILES_FORCE_REKEY=true
        export DOTFILES_FORCE_REKEY
    fi
}

main
