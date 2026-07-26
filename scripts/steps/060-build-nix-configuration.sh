#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

main() {
    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]

    local -a outputs=(system)
    if [[ "$(uname -s)" == 'Linux' ]]; then
        outputs+=(home)
    fi

    local output
    for output in "${outputs[@]}"; do
        local result
        result="$(
            nix build \
                --accept-flake-config \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#configurationBuilds.${DOTFILES_HOST}.${output}"
        )"

        [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

        export "DOTFILES_$(printf '%s' "${output}" | LC_ALL=C tr '[:lower:]' '[:upper:]')_RESULT=${result}"
    done
}

main
