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
            --impure \
            --raw \
            --expr "(import ./nix/r2-cache.nix).systems.\"${system}\".credentialsFile"
    )"

    local cache_url
    cache_url="$(
        nix eval \
            --impure \
            --raw \
            --expr '(import ./nix/r2-cache.nix).url'
    )"

    [[ "${credentials}" == /* ]]
    [[ "${cache_url}" == s3://* ]]

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        sudo install -d -m 700 "${credentials%/*}"

        sudo sh -c '
            umask 077
            cat >"$1"
            chmod 600 "$1"
        ' sh "${credentials}" <<EOF
[default]
aws_access_key_id = ${R2_ACCESS_KEY_ID}
aws_secret_access_key = ${R2_SECRET_ACCESS_KEY}
EOF

        unset R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY
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
    fi

    case "${system}" in
    aarch64-darwin)
        sudo launchctl \
            kickstart -k system/org.nixos.nix-daemon
        ;;
    x86_64-linux)
        sudo systemctl restart nix-daemon.service
        ;;
    *) return 1 ;;
    esac

    local root_nix='/nix/var/nix/profiles/default/bin/nix'
    [[ -x "${root_nix}" ]] || return 1

    sudo -H env \
        "AWS_SHARED_CREDENTIALS_FILE=${credentials}" \
        "${root_nix}" store info \
        --store "${cache_url}"
)

main
