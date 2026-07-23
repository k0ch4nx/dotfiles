#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]] || [[ "${DOTFILES_HOST:-}" != "ubuntu-wsl" ]]; then
        return
    fi

    sudo /usr/bin/apt update
    sudo /usr/bin/apt full-upgrade -y
    sudo /usr/bin/apt autoremove --purge -y
    sudo /usr/bin/do-release-upgrade
}

main
