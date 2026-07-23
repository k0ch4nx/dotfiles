#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    local credentials
    local credentials_dir
    local result

    [[ -n "${DOTFILES_DIR:-}" ]] || exit 1
    [[ -n "${DOTFILES_HOST:-}" ]] || exit 1

    case "${DOTFILES_HOST}" in
        macbook-pro)
            credentials="/var/root/.aws/credentials"
            ;;
        ubuntu-wsl)
            credentials="/root/.aws/credentials"
            ;;
        *)
            exit 1
            ;;
    esac

    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        if [[ -z "${R2_ACCESS_KEY_ID:-}" && -z "${R2_SECRET_ACCESS_KEY:-}" ]]; then
            return
        fi

        [[ -n "${R2_ACCESS_KEY_ID:-}" ]] || exit 1
        [[ -n "${R2_SECRET_ACCESS_KEY:-}" ]] || exit 1

        credentials_dir="${credentials%/*}"

        (
            local temporary_file

            set +x
            umask 077
            temporary_file="$(mktemp /tmp/r2-credentials.XXXXXX)"
            trap 'rm -f "${temporary_file}"' EXIT HUP INT TERM

            printf \
                '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
                "${R2_ACCESS_KEY_ID}" \
                "${R2_SECRET_ACCESS_KEY}" \
                >"${temporary_file}"

            if ((EUID == 0)); then
                install -d -m 700 "${credentials_dir}"
                install -m 600 "${temporary_file}" "${credentials}"
            else
                sudo /usr/bin/install -d -m 700 "${credentials_dir}"
                sudo /usr/bin/install -m 600 "${temporary_file}" "${credentials}"
            fi
        )

        unset R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY
        return
    fi

    if sudo /bin/test -s "${credentials}"; then
        return
    fi

    case "${DOTFILES_HOST}" in
        macbook-pro)
            result="$(
                nix build \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    "path:${DOTFILES_DIR}#darwinConfigurations.cache-bootstrap.config.system.build.toplevel"
            )"

            [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || exit 1
            nix path-info "${result}" >/dev/null

            sudo "${result}/sw/bin/darwin-rebuild" activate
            sudo /bin/launchctl kickstart -k system/org.nixos.activate-agenix
            sudo /bin/launchctl kickstart -k system/org.nixos.nix-daemon
            ;;
        ubuntu-wsl)
            result="$(
                nix build \
                    --accept-flake-config \
                    --impure \
                    --no-link \
                    --no-update-lock-file \
                    --print-out-paths \
                    "path:${DOTFILES_DIR}#systemConfigs.cache-bootstrap"
            )"

            [[ "${result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || exit 1
            nix path-info "${result}" >/dev/null

            sudo "${result}/bin/register-profile"
            sudo "${result}/bin/activate"
            sudo /usr/bin/systemctl daemon-reload
            sudo /usr/bin/systemctl start agenix-install-secrets.service
            sudo /usr/bin/systemctl restart nix-daemon.service
            ;;
    esac

    sudo /bin/test -s "${credentials}"
}

main
