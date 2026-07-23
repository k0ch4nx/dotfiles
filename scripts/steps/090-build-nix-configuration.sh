#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    local home_result
    local system_result

    [[ -n "${DOTFILES_DIR:-}" ]] || exit 1
    [[ -n "${DOTFILES_HOST:-}" ]] || exit 1
    [[ -n "${DOTFILES_USER:-}" ]] || exit 1

    system_result="$(
        nix build \
            --accept-flake-config \
            --impure \
            --no-link \
            --no-update-lock-file \
            --print-out-paths \
            "path:${DOTFILES_DIR}#configurationBuilds.${DOTFILES_HOST}.system"
    )"

    [[ "${system_result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || exit 1
    nix path-info "${system_result}" >/dev/null
    export DOTFILES_SYSTEM_RESULT="${system_result}"

    if [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        home_result="$(
            nix build \
                --accept-flake-config \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#configurationBuilds.${DOTFILES_HOST}.home"
        )"

        [[ "${home_result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || exit 1
        nix path-info "${home_result}" >/dev/null
        export DOTFILES_HOME_RESULT="${home_result}"
    fi
}

main
