#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function trust_wsl_nix_user() {
    if [[ ! -r /proc/sys/kernel/osrelease ]] ||
        ! grep -qi microsoft /proc/sys/kernel/osrelease ||
        [[ "$(/usr/bin/id -u)" == 0 ]]; then
        return
    fi

    local trusted_user
    local trust_setting

    trusted_user="$(/usr/bin/id -un)"
    [[ "${trusted_user}" =~ ^[a-z_][a-z0-9_-]*$ ]] || exit 1
    trust_setting="extra-trusted-users = ${trusted_user}"

    if sudo /usr/bin/grep -Fqx "${trust_setting}" /etc/nix/nix.conf; then
        return
    fi

    printf '%s\n' "${trust_setting}" |
        sudo /usr/bin/tee -a /etc/nix/nix.conf >/dev/null
    sudo /usr/bin/systemctl restart nix-daemon.service
}

function main() {
    local profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

    if [[ -r "${profile}" ]]; then
        # shellcheck disable=SC1090
        source "${profile}"
    fi

    if ! command -v nix >/dev/null 2>&1; then
        # https://nixos.org/download/

        if [[ "$(uname -s)" == "Darwin" ]]; then
            [[ "$(uname -m)" == "arm64" ]] || exit 1
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --yes
        elif [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease; then
            if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
                curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon --yes
            else
                curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
            fi
        else
            exit 1
        fi

        if [[ -r "${profile}" ]]; then
            # shellcheck disable=SC1090
            source "${profile}"
        fi
    fi

    command -v nix >/dev/null 2>&1
    trust_wsl_nix_user
}

main
