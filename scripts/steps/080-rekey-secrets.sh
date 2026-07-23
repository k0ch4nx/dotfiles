#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    local plugin
    local system

    [[ -n "${DOTFILES_DIR:-}" ]] || exit 1

    (
        cd "${DOTFILES_DIR}"

        plugin="$(nix build --no-link --print-out-paths 'nixpkgs#age-plugin-yubikey^out')"
        system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

        if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
            PATH="${plugin}/bin:${PATH}" \
                nix run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey" \
                -- \
                --dummy
            return
        fi

        PATH="${plugin}/bin:${PATH}" \
            nix run \
            --impure \
            --no-update-lock-file \
            "path:.#agenix-rekey.${system}.generate"

        PATH="${plugin}/bin:${PATH}" \
            nix run \
            --impure \
            --no-update-lock-file \
            "path:.#agenix-rekey.${system}.rekey"
    )
}

main
