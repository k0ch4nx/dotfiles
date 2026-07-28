#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        return 0
    fi

    local restore_system_pcscd_service=false
    local restore_system_pcscd_socket=false
    local stop_bootstrap_pcscd=false

    # shellcheck disable=SC2329
    function cleanup_pcscd() {
        if [[ "${stop_bootstrap_pcscd}" == 'true' ]]; then
            sudo systemctl stop dotfiles-bootstrap-pcscd.service || true
        fi

        if [[ "${restore_system_pcscd_service}" == 'true' || "${restore_system_pcscd_socket}" == 'true' ]]; then
            sudo rm -f /run/pcscd/pcscd.comm
        fi

        if [[ "${restore_system_pcscd_socket}" == 'true' ]]; then
            sudo systemctl start pcscd.socket || true
        fi

        if [[ "${restore_system_pcscd_service}" == 'true' ]]; then
            sudo systemctl start pcscd.service || true
        fi
    }

    trap cleanup_pcscd EXIT

    local plugin
    plugin="$(nix build --no-link --print-out-paths 'nixpkgs#age-plugin-yubikey^out')"

    local system
    system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

    export PATH="${plugin}/bin:${PATH}"

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        if [[ "$(uname -s)" == 'Linux' ]]; then
            if ! systemctl is-active --quiet dotfiles-pcscd.service; then
                if systemctl is-active --quiet pcscd.service; then
                    restore_system_pcscd_service=true
                fi

                if systemctl is-active --quiet pcscd.socket; then
                    restore_system_pcscd_socket=true
                fi

                if [[ "${restore_system_pcscd_service}" == 'true' || "${restore_system_pcscd_socket}" == 'true' ]]; then
                    sudo systemctl stop pcscd.service pcscd.socket
                    sudo rm -f /run/pcscd/pcscd.comm
                fi

                [[ ! -S /run/pcscd/pcscd.comm ]]

                local ccid
                ccid="$(
                    nix build \
                        --no-link \
                        --print-out-paths \
                        'nixpkgs#ccid^out'
                )"

                local pcscd
                pcscd="$(
                    nix build \
                        --no-link \
                        --print-out-paths \
                        'nixpkgs#pcsclite^out'
                )"

                sudo systemd-run \
                    --quiet \
                    --collect \
                    --unit=dotfiles-bootstrap-pcscd \
                    --property=RuntimeDirectory=pcscd \
                    --property=RuntimeDirectoryMode=0755 \
                    --setenv="PCSCLITE_HP_DROPDIR=${ccid}/pcsc/drivers" \
                    "${pcscd}/bin/pcscd" \
                    -f \
                    -x \
                    -c /dev/null
                stop_bootstrap_pcscd=true
            fi

            for _ in {1..50}; do
                [[ -S /run/pcscd/pcscd.comm ]] && break
                sleep 0.1
            done

            [[ -S /run/pcscd/pcscd.comm ]]
        fi

        if [[ ! -f "${DOTFILES_DIR}/secrets/r2-credentials.age" ]]; then
            nix run \
                --accept-flake-config \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.generate"
        fi

        nix run \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            "path:.#agenix-rekey.${system}.rekey"
    fi
)

main
