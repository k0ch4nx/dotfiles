#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function credentials_file() {
    case "${DOTFILES_HOST}" in
        macbook-pro)
            printf '%s\n' "/var/root/.aws/credentials"
            ;;
        ubuntu-wsl)
            printf '%s\n' "/root/.aws/credentials"
            ;;
        *)
            return 1
            ;;
    esac
}

function build_output() {
    local output="$1"

    nix build \
        --accept-flake-config \
        --impure \
        --no-link \
        --no-update-lock-file \
        --print-out-paths \
        "path:${DOTFILES_DIR}#${output}"
}

function is_valid_store_path() {
    local store_path="$1"

    [[ "${store_path}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1
    nix path-info "${store_path}" >/dev/null
}

function r2_credentials_are_ready() {
    local credentials="$1"
    local metadata

    sudo /bin/test -s "${credentials}" || return 1

    case "${DOTFILES_HOST}" in
        macbook-pro)
            metadata="$(sudo /usr/bin/stat -f '%Lp:%Su:%Sg' "${credentials}")"
            [[ "${metadata}" == "600:root:wheel" ]] || return 1
            ;;
        ubuntu-wsl)
            metadata="$(sudo /usr/bin/stat -c '%a:%U:%G' "${credentials}")"
            [[ "${metadata}" == "600:root:root" ]] || return 1
            ;;
        *)
            return 1
            ;;
    esac

    sudo /usr/bin/awk -F ' = ' '
        NR == 1 { header = ($0 == "[default]"); next }
        $1 == "aws_access_key_id" && length($2) == 32 { access = 1 }
        $1 == "aws_secret_access_key" && length($2) == 64 { secret = 1 }
        END { exit !(header && access && secret) }
    ' "${credentials}"
}

function prepare_ci_credentials() {
    [[ "${GITHUB_ACTIONS:-}" == "true" ]] || return

    if [[ -z "${R2_ACCESS_KEY_ID:-}" && -z "${R2_SECRET_ACCESS_KEY:-}" ]]; then
        return
    fi

    [[ -n "${R2_ACCESS_KEY_ID:-}" ]] || exit 1
    [[ -n "${R2_SECRET_ACCESS_KEY:-}" ]] || exit 1

    local credentials
    local credentials_dir

    credentials="$(credentials_file)"
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
}

function bootstrap_local_cache() {
    [[ "${GITHUB_ACTIONS:-}" != "true" ]] || return

    local credentials
    local result

    credentials="$(credentials_file)"
    r2_credentials_are_ready "${credentials}" && return

    case "${DOTFILES_HOST}" in
        macbook-pro)
            result="$(
                build_output \
                    "darwinConfigurations.cache-bootstrap.config.system.build.toplevel"
            )"
            is_valid_store_path "${result}" || exit 1

            sudo "${result}/sw/bin/darwin-rebuild" activate
            sudo /bin/launchctl kickstart -k system/org.nixos.activate-agenix
            sudo /bin/launchctl kickstart -k system/org.nixos.nix-daemon
            ;;
        ubuntu-wsl)
            result="$(build_output "systemConfigs.cache-bootstrap")"
            is_valid_store_path "${result}" || exit 1

            sudo "${result}/bin/register-profile"
            sudo "${result}/bin/activate"
            sudo /usr/bin/systemctl daemon-reload
            sudo /usr/bin/systemctl start agenix-install-secrets.service
            sudo /usr/bin/systemctl restart nix-daemon.service
            ;;
        *)
            exit 1
            ;;
    esac

    r2_credentials_are_ready "${credentials}"
}

function main() {
    local home_result
    local system_result

    [[ -n "${DOTFILES_DIR:-}" ]] || exit 1
    [[ -n "${DOTFILES_HOST:-}" ]] || exit 1
    [[ -n "${DOTFILES_USER:-}" ]] || exit 1
    command -v nix >/dev/null 2>&1 || exit 1

    prepare_ci_credentials
    bootstrap_local_cache

    system_result="$(build_output "configurationBuilds.${DOTFILES_HOST}.system")"
    is_valid_store_path "${system_result}" || exit 1
    export DOTFILES_SYSTEM_RESULT="${system_result}"

    if [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        home_result="$(build_output "configurationBuilds.${DOTFILES_HOST}.home")"
        is_valid_store_path "${home_result}" || exit 1
        export DOTFILES_HOME_RESULT="${home_result}"
    fi
}

main
