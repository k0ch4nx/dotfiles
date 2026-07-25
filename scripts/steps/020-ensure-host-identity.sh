#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]
    [[ -n "${DOTFILES_USER:-}" ]]

    local identity_dir="${DOTFILES_DIR}/secrets/hosts"
    local identity_name="${DOTFILES_HOST}-${DOTFILES_USER}"
    local private_key="${identity_dir}/${identity_name}-key.txt"
    local public_key="${identity_dir}/${identity_name}.pub"

    umask 077
    install -d -m 700 "${identity_dir}"

    if [[ ! -f "${private_key}" ]]; then
        nix shell nixpkgs#rage -c \
            rage-keygen -o "${private_key}" >/dev/null
    fi

    nix shell nixpkgs#rage -c \
        rage-keygen -y "${private_key}" >"${public_key}"
)

main
