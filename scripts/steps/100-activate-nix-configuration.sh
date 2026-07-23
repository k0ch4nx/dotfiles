#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        exit 1
    fi

    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1
    [[ ! "${DOTFILES_HOST:-}" ]] && exit 1
    [[ "${DOTFILES_SYSTEM_RESULT:-}" != /nix/store/* ]] && exit 1
    [[ "${DOTFILES_SYSTEM_RESULT}" == *$'\n'* ]] && exit 1

    if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
        sudo /nix/var/nix/profiles/default/bin/nix-env \
            --profile /nix/var/nix/profiles/system \
            --set "${DOTFILES_SYSTEM_RESULT}"
        sudo "${DOTFILES_SYSTEM_RESULT}/sw/bin/darwin-rebuild" activate
    elif [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        [[ "${DOTFILES_HOME_RESULT:-}" != /nix/store/* ]] && exit 1
        [[ "${DOTFILES_HOME_RESULT}" == *$'\n'* ]] && exit 1

        sudo "${DOTFILES_SYSTEM_RESULT}/bin/register-profile"
        sudo "${DOTFILES_SYSTEM_RESULT}/bin/activate"
        "${DOTFILES_HOME_RESULT}/activate"
    else
        exit 1
    fi
}

main
