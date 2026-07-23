#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function bootstrap_nix_cache() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        return
    fi

    local cache_url
    local credentials_metadata
    local credentials_file
    local cache_bootstrap_result
    local nix_command

    nix_command="/nix/var/nix/profiles/default/bin/nix"
    [[ -x "${nix_command}" ]] || exit 1

    function is_valid_store_path() {
        local store_path="$1"

        [[ "${store_path}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1
        "${nix_command}" path-info "${store_path}" >/dev/null
    }

    if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
        credentials_file="/var/root/.aws/credentials"
    elif [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        credentials_file="/root/.aws/credentials"
    else
        exit 1
    fi

    function r2_credentials_are_ready() {
        sudo /bin/test -f "${credentials_file}" || return 1
        sudo /bin/test -s "${credentials_file}" || return 1

        if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
            credentials_metadata="$(sudo /usr/bin/stat -f '%Lp:%Su:%Sg' "${credentials_file}")"
            [[ "${credentials_metadata}" == "600:root:wheel" ]] || return 1
        else
            credentials_metadata="$(sudo /usr/bin/stat -c '%a:%U:%G' "${credentials_file}")"
            [[ "${credentials_metadata}" == "600:root:root" ]] || return 1
        fi

        sudo /usr/bin/awk -F ' = ' '
            NR == 1 { header = ($0 == "[default]"); next }
            $1 == "aws_access_key_id" && length($2) == 32 { access = 1 }
            $1 == "aws_secret_access_key" && length($2) == 64 { secret = 1 }
            END { exit !(header && access && secret) }
        ' "${credentials_file}"
    }

    if ! r2_credentials_are_ready; then
        if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
            cache_bootstrap_result="$(
                "${nix_command}" \
                build \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#darwinConfigurations.cache-bootstrap.config.system.build.toplevel"
            )"
            is_valid_store_path "${cache_bootstrap_result}" || exit 1

            sudo "${cache_bootstrap_result}/sw/bin/darwin-rebuild" activate
            sudo /bin/launchctl kickstart -k system/org.nixos.activate-agenix
            sudo /bin/launchctl kickstart -k system/org.nixos.r2-nix-cache-credentials
        else
            cache_bootstrap_result="$(
                "${nix_command}" \
                build \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#systemConfigs.cache-bootstrap"
            )"
            is_valid_store_path "${cache_bootstrap_result}" || exit 1

            sudo "${cache_bootstrap_result}/bin/register-profile"
            sudo "${cache_bootstrap_result}/bin/activate"
            sudo /usr/bin/systemctl daemon-reload
            sudo /usr/bin/systemctl start agenix-install-secrets.service
        fi

        for _ in {1..30}; do
            if r2_credentials_are_ready; then
                break
            fi
            sleep 1
        done

        r2_credentials_are_ready

        if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
            sudo /bin/launchctl kickstart -k system/org.nixos.nix-daemon
        else
            sudo /usr/bin/systemctl restart nix-daemon.service
        fi
    fi

    r2_credentials_are_ready

    cache_url="$("${nix_command}" eval --raw --no-update-lock-file "path:${DOTFILES_DIR}#cacheSettings.url")"
    sudo -H /usr/bin/env \
        "AWS_SHARED_CREDENTIALS_FILE=${credentials_file}" \
        "${nix_command}" \
        store ping \
        --store "${cache_url}"
}

function configure_ci_nix_cache() {
    if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
        return
    fi

    if [[ -z "${R2_ACCESS_KEY_ID:-}" && -z "${R2_SECRET_ACCESS_KEY:-}" ]]; then
        return
    fi

    [[ -n "${R2_ACCESS_KEY_ID:-}" ]] || exit 1
    [[ -n "${R2_SECRET_ACCESS_KEY:-}" ]] || exit 1

    local cache_url
    local ci_public_key
    local local_public_key
    local nix_config="${NIX_CONFIG:-}"
    local root_aws_dir

    if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
        root_aws_dir="/var/root/.aws"
    elif [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        root_aws_dir="/root/.aws"
    else
        exit 1
    fi

    (
        local credentials

        credentials="$(mktemp /tmp/r2-credentials.XXXXXX)"
        trap 'rm -f "${credentials}"' EXIT HUP INT TERM
        umask 077

        printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
            "${R2_ACCESS_KEY_ID}" \
            "${R2_SECRET_ACCESS_KEY}" >"${credentials}"

        if ((EUID == 0)); then
            install -d -m 700 "${root_aws_dir}"
            install -m 600 "${credentials}" "${root_aws_dir}/credentials"
        else
            sudo /usr/bin/install -d -m 700 "${root_aws_dir}"
            sudo /usr/bin/install -m 600 "${credentials}" "${root_aws_dir}/credentials"
        fi
    )

    unset R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY

    cache_url="$(nix eval --raw --no-update-lock-file "path:${DOTFILES_DIR}#cacheSettings.url")"
    local_public_key="$(nix eval --raw --no-update-lock-file "path:${DOTFILES_DIR}#cacheSettings.localPublicKey")"
    ci_public_key="$(nix eval --raw --no-update-lock-file "path:${DOTFILES_DIR}#cacheSettings.ciPublicKey")"

    if [[ -n "${nix_config}" ]]; then
        nix_config+=$'\n'
    fi

    nix_config+="extra-experimental-features = nix-command flakes"$'\n'
    nix_config+="extra-substituters = ${cache_url}"$'\n'
    nix_config+="extra-trusted-public-keys = ${local_public_key} ${ci_public_key}"$'\n'
    nix_config+="fallback = true"
    NIX_CONFIG="${nix_config}"
    export NIX_CONFIG
}

function main() {
    local home_result
    local nix_command="/nix/var/nix/profiles/default/bin/nix"
    local system_result

    [[ ! "${DOTFILES_DIR:-}" ]] && exit 1
    [[ ! "${DOTFILES_HOST:-}" ]] && exit 1
    [[ ! "${DOTFILES_USER:-}" ]] && exit 1
    [[ -x "${nix_command}" ]] || exit 1

    function is_valid_build_result() {
        local store_path="$1"

        [[ "${store_path}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1
        "${nix_command}" path-info "${store_path}" >/dev/null
    }

    configure_ci_nix_cache
    bootstrap_nix_cache

    if [[ "${DOTFILES_HOST}" == "macbook-pro" ]]; then
        system_result="$(
            "${nix_command}" \
                build \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#darwinConfigurations.${DOTFILES_HOST}.config.system.build.toplevel"
        )"
    elif [[ "${DOTFILES_HOST}" == "ubuntu-wsl" ]]; then
        system_result="$(
            "${nix_command}" \
                build \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#systemConfigs.${DOTFILES_HOST}"
        )"
        home_result="$(
            "${nix_command}" \
                build \
                --impure \
                --no-link \
                --no-update-lock-file \
                --print-out-paths \
                "path:${DOTFILES_DIR}#homeConfigurations.\"${DOTFILES_USER}@${DOTFILES_HOST}\".activationPackage"
        )"
        is_valid_build_result "${home_result}" || exit 1
        DOTFILES_HOME_RESULT="${home_result}"
        export DOTFILES_HOME_RESULT
    else
        exit 1
    fi

    is_valid_build_result "${system_result}" || exit 1
    DOTFILES_SYSTEM_RESULT="${system_result}"
    export DOTFILES_SYSTEM_RESULT
}

main
