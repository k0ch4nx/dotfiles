#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    if ! command -v minecraft-provision >/dev/null 2>&1; then
        return
    fi

    minecraft-provision
}

main
