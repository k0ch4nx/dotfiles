#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    if [[ "$(uname -s)" != 'Linux' ]]; then
        return
    fi

    sudo apt-get update
    sudo apt-get full-upgrade -y
    sudo apt-get autoremove --purge -y

    if sudo do-release-upgrade --check-dist-upgrade-only; then
        sudo do-release-upgrade
    fi
}

main
