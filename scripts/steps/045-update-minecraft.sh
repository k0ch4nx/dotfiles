#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

[[ "${DOTFILES_SKIP_UPDATES:-}" == "1" ]] && return 0

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

    "${DOTFILES_DIR}/scripts/steps/900-minecraft-update.sh"

    git add -- minecraft

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        set -x
    fi
)

main
