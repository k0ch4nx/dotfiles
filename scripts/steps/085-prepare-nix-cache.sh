#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        set +x

        if [[ -z "${R2_ACCESS_KEY_ID:-}" && -z "${R2_SECRET_ACCESS_KEY:-}" ]]; then
            return
        fi

        [[ -n "${R2_ACCESS_KEY_ID:-}" ]]
        [[ -n "${R2_SECRET_ACCESS_KEY:-}" ]]
    fi

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    local system
    system="$(
        nix eval \
            --impure \
            --raw \
            --expr 'builtins.currentSystem'
    )"

    local credentials
    credentials="$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            "path:.#cacheSettings.systems.\"${system}\".credentialsFile"
    )"

    local cache_url
    cache_url="$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            'path:.#cacheSettings.url'
    )"

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        if ((EUID == 0)); then
            install -d -m 700 "${credentials%/*}"

            sh -c '
            umask 077
            cat >"$1"
        ' sh "${credentials}" <<EOF
[default]
aws_access_key_id = ${R2_ACCESS_KEY_ID}
aws_secret_access_key = ${R2_SECRET_ACCESS_KEY}
EOF
        else
            sudo install -d -m 700 "${credentials%/*}"

            sudo sh -c '
            umask 077
            cat >"$1"
        ' sh "${credentials}" <<EOF
[default]
aws_access_key_id = ${R2_ACCESS_KEY_ID}
aws_secret_access_key = ${R2_SECRET_ACCESS_KEY}
EOF
        fi

        unset R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY

        case "${system}" in
        aarch64-darwin)
            sudo launchctl setenv \
                AWS_SHARED_CREDENTIALS_FILE "${credentials}"
            sudo launchctl \
                kickstart -k system/org.nixos.nix-daemon
            ;;
        x86_64-linux)
            if sudo systemctl is-active --quiet nix-daemon.service 2>/dev/null; then
                sudo systemctl set-environment \
                    "AWS_SHARED_CREDENTIALS_FILE=${credentials}"
                sudo systemctl restart nix-daemon.service
            fi
            ;;
        esac
    elif ! sudo test -s "${credentials}"; then
        local result

        case "${system}" in
        aarch64-darwin)
            result="$(
                nix build \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    'path:.#darwinConfigurations.cache-bootstrap.config.system.build.toplevel'
            )"

            [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] ||
                return 1
            nix path-info "${result}" >/dev/null

            sudo "${result}/sw/bin/darwin-rebuild" activate
            sudo launchctl \
                kickstart -k system/org.nixos.activate-agenix
            ;;
        x86_64-linux)
            result="$(
                nix build \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    'path:.#systemConfigs.cache-bootstrap'
            )"

            [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] ||
                return 1
            nix path-info "${result}" >/dev/null

            sudo "${result}/bin/register-profile"
            sudo "${result}/bin/activate"
            sudo systemctl daemon-reload
            sudo systemctl \
                start agenix-install-secrets.service
            ;;
        *)
            return 1
            ;;
        esac

        for _ in {1..30}; do
            sudo test -s "${credentials}" && break
            sleep 1
        done

        sudo test -s "${credentials}" || return 1

        case "${system}" in
        aarch64-darwin)
            sudo launchctl \
                kickstart -k system/org.nixos.nix-daemon
            ;;
        x86_64-linux)
            sudo systemctl restart nix-daemon.service
            ;;
        esac
    fi

    sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${credentials}" \
        nix store info \
        --store "${cache_url}"
)

main
