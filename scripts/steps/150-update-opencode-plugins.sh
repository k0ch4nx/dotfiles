#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

[[ "${SKIP_UPDATES:-}" == "1" ]] && return 0

function main() {
    command -v opencode2 >/dev/null 2>&1 || return

    local service_was_running=false
    if [[ "$(opencode2 service status)" == http* ]]; then
        service_was_running=true
    else
        opencode2 service start >/dev/null
    fi

    local max_attempts=15
    for ((attempt = 0; attempt < max_attempts; attempt++)); do
        opencode2 plugin check 2>/dev/null | grep -q '^Server' && break
        sleep 2
    done

    opencode2 plugin update

    if $service_was_running; then
        opencode2 service restart >/dev/null
    else
        opencode2 service stop >/dev/null
    fi
}

main
