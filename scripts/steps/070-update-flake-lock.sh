#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1

    (
        cd "${DOTFILES_DIR}" || exit 1

        set +x

        if [[ -z "${GH_TOKEN:-}" ]]; then
            exec nix flake update
        fi

        local nix_config="${NIX_CONFIG:-}"

        if [[ -n "${nix_config}" ]]; then
            nix_config+=$'\n'
        fi

        nix_config+="access-tokens = github.com=${GH_TOKEN}"

        NIX_CONFIG="${nix_config}" exec nix flake update
    )
}

main
