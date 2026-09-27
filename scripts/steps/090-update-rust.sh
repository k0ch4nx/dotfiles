#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

[[ "${SKIP_UPDATES:-}" == "1" ]] && return 0

function main() {
    rustup update
}

main
