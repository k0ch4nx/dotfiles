#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]] || [[ "${DOTFILES_HOST:-}" != "macbook-pro" ]]; then
        return
    fi

    softwareupdate --install --all
}

main
