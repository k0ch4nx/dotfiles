#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function find_age_plugin_yubikey() (
    local candidate
    for candidate in age-plugin-yubikey age-plugin-yubikey.exe; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            command -v "${candidate}"
            return 0
        fi
    done

    local plugin
    plugin="$(
        nix build \
            --no-link \
            --print-out-paths \
            'nixpkgs#age-plugin-yubikey^out'
    )/bin/age-plugin-yubikey"

    [[ -x "${plugin}" ]]
    printf '%s' "${plugin}"
)

function main() (
    set +x

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        return 0
    fi

    [[ -n "${HOME:-}" ]]

    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local identity_file="${AGE_YUBIKEY_IDENTITY_FILE:-${config_home}/age/yubikey-identity.txt}"

    if [[ -s "${identity_file}" ]]; then
        return 0
    fi

    local age_plugin_yubikey
    age_plugin_yubikey="$(find_age_plugin_yubikey)"

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "${temporary_directory}"' EXIT

    printf 'No YubiKey age identity exists at %s.\n' "${identity_file}"
    printf 'Select the existing age identity on the attached YubiKey.\n'

    (
        cd -- "${temporary_directory}"
        "${age_plugin_yubikey}"
    )

    local generated_identity
    generated_identity="$(
        find "${temporary_directory}" \
            -maxdepth 1 \
            -type f \
            -name 'age-yubikey-identity-*.txt' \
            -print \
            -quit
    )"

    if [[ -z "${generated_identity}" || ! -s "${generated_identity}" ]]; then
        printf 'age-plugin-yubikey did not create an identity file.\n' >&2
        return 1
    fi

    umask 077
    install -d -m 700 "${identity_file%/*}"
    install -m 600 "${generated_identity}" "${identity_file}"
)

main
