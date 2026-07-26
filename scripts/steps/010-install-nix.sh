#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

main() {
    local profile='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

    if [[ -r "${profile}" ]]; then
        # shellcheck disable=SC1090
        source "${profile}"
    fi

    if command -v nix >/dev/null 2>&1; then
        return
    fi

    local system

    system="$(uname -s)"

    case "${system}" in
    Darwin)
        curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install |
            sh -s -- --yes
        ;;
    Linux)
        if [[ ! -r /proc/sys/kernel/osrelease ]] ||
            ! grep -qi microsoft /proc/sys/kernel/osrelease; then
            printf 'Unsupported Linux environment\n' >&2
            return 1
        fi

        curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install |
            sh -s -- --daemon --yes
        ;;
    *)
        printf 'Unsupported operating system: %s\n' "${system}" >&2
        return 1
        ;;
    esac

    if [[ -r "${profile}" ]]; then
        # shellcheck disable=SC1090
        source "${profile}"
    fi

    if ! command -v nix >/dev/null 2>&1; then
        printf 'Nix was installed, but the nix command is unavailable\n' >&2
        return 1
    fi
}

main
