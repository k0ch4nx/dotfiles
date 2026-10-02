#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    nix-collect-garbage \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false

    local root_nix_collect_garbage='/nix/var/nix/profiles/default/bin/nix-collect-garbage'
    [[ -x "${root_nix_collect_garbage}" ]]

    sudo "${root_nix_collect_garbage}" \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false
}

main
