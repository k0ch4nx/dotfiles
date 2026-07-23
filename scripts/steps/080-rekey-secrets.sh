#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function r2_credentials_are_ready() {
    local credentials_file

    if [[ "${DOTFILES_HOST:-}" == "macbook-pro" ]]; then
        credentials_file="/var/root/.aws/credentials"
    elif [[ "${DOTFILES_HOST:-}" == "ubuntu-wsl" ]]; then
        credentials_file="/root/.aws/credentials"
    else
        return 1
    fi

    sudo /bin/test -f "${credentials_file}" || return 1
    sudo /usr/bin/awk -F ' = ' '
        NR == 1 { header = ($0 == "[default]"); next }
        $1 == "aws_access_key_id" && length($2) == 32 { access = 1 }
        $1 == "aws_secret_access_key" && length($2) == 64 { secret = 1 }
        END { exit !(header && access && secret) }
    ' "${credentials_file}"
}

function main() {
    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1

    (
        cd "${DOTFILES_DIR}" || exit 1

        local plugin
        local system

        plugin="$(nix build --no-link --print-out-paths 'nixpkgs#age-plugin-yubikey^out')"
        system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

        if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
            PATH="${plugin}/bin:${PATH}" \
                nix \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey" \
                -- \
                --dummy
        elif [[ "${DOTFILES_FORCE_REKEY:-}" == "true" ]] || ! r2_credentials_are_ready; then
            PATH="${plugin}/bin:${PATH}" \
                nix \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey" \
                -- \
                --force
        else
            PATH="${plugin}/bin:${PATH}" \
                nix \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey"
        fi
    )
}

main
