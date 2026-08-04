#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

main() {
    [[ -n "${DOTFILES_DIR:-}" ]]
    [[ -n "${DOTFILES_HOST:-}" ]]

    local cache_disable_file="${NIX_CACHE_DISABLE_FILE:-/tmp/dotfiles-disable-r2-cache}"
    local fallback_substituters=''

    if [[ -e "${cache_disable_file}" ]]; then
        fallback_substituters="$(
            DOTFILES_R2_CACHE_FILE="${DOTFILES_DIR}/nix/r2-cache.nix" \
                nix eval \
                --impure \
                --raw \
                --expr '
                    let
                      cache = import (
                        builtins.toPath (builtins.getEnv "DOTFILES_R2_CACHE_FILE")
                      );
                    in
                    builtins.concatStringsSep " " (
                      builtins.filter (url: builtins.substring 0 5 url != "s3://") cache.substituters
                    )
                '
        )"

        [[ -n "${fallback_substituters}" ]]
    fi

    local -a outputs=(system)
    if [[ "$(uname -s)" == 'Linux' ]]; then
        outputs+=(home)
    fi

    local output
    for output in "${outputs[@]}"; do
        local result

        if [[ -n "${fallback_substituters}" ]]; then
            result="$(
                nix build \
                    --option substituters "${fallback_substituters}" \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    "path:${DOTFILES_DIR}#configurationBuilds.${DOTFILES_HOST}.${output}"
            )"
        else
            result="$(
                nix build \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    "path:${DOTFILES_DIR}#configurationBuilds.${DOTFILES_HOST}.${output}"
            )"
        fi

        [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

        export "DOTFILES_$(printf '%s' "${output}" | LC_ALL=C tr '[:lower:]' '[:upper:]')_RESULT=${result}"
    done
}

main
