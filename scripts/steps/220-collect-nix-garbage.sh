#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        return
    fi

    local gc_command="/nix/var/nix/profiles/default/bin/nix-collect-garbage"
    [[ -x "${gc_command}" ]] || exit 1

    "${gc_command}" \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false

    sudo "${gc_command}" \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false
}

main
