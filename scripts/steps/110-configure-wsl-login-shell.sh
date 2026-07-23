#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]] || [[ "${DOTFILES_HOST:-}" != "ubuntu-wsl" ]]; then
        return
    fi

    local current_shell
    local passwd_entry
    local user_home
    local zsh_path

    [[ "${DOTFILES_USER:-}" =~ ^[a-z_][a-z0-9_-]*$ ]] || exit 1

    passwd_entry="$(/usr/bin/getent passwd "${DOTFILES_USER}")"
    IFS=: read -r _ _ _ _ _ user_home current_shell <<<"${passwd_entry}"

    [[ "${user_home}" == "/home/${DOTFILES_USER}" ]] || exit 1
    zsh_path="${user_home}/.nix-profile/bin/zsh"
    [[ -x "${zsh_path}" ]] || exit 1

    if ! /usr/bin/grep -Fqx "${zsh_path}" /etc/shells; then
        printf '%s\n' "${zsh_path}" |
            sudo /usr/bin/tee -a /etc/shells >/dev/null
    fi

    if [[ "${current_shell}" != "${zsh_path}" ]]; then
        sudo /usr/bin/chsh -s "${zsh_path}" "${DOTFILES_USER}"
    fi
}

main
