#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

main() (
    [[ -n "${DOTFILES_DIR:-}" ]] || {
        printf 'DOTFILES_DIR is not set\n' >&2
        exit 1
    }

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        set -x
    fi

    cd -- "${DOTFILES_DIR}"

    set +x

    if [[ -n "${GH_TOKEN:-}" ]]; then
        local nix_config="${NIX_CONFIG:-}"

        if [[ -n "${nix_config}" ]]; then
            nix_config+=$'\n'
        fi

        nix_config+="access-tokens = github.com=${GH_TOKEN}"
        export NIX_CONFIG="${nix_config}"
    fi

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        set -x
    fi

    nix run --accept-flake-config .#write-flake
    exec nix flake update --accept-flake-config
)

main
