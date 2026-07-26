#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    local plugin
    plugin="$(nix build --no-link --print-out-paths 'nixpkgs#age-plugin-yubikey^out')"

    local system
    system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

    export PATH="${plugin}/bin:${PATH}"

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        if [[ ! -f "${DOTFILES_DIR}/secrets/r2-credentials.age" ]]; then
            nix run \
                --accept-flake-config \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.generate"
        fi

        nix run \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            "path:.#agenix-rekey.${system}.rekey"
    else
        nix run \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            "path:.#agenix-rekey.${system}.rekey" \
            -- \
            --dummy
    fi
)

main
