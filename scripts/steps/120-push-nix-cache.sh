#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1

    nix run \
        --accept-flake-config \
        --impure \
        --no-update-lock-file \
        "path:${DOTFILES_DIR}#cache-push"
}

main
