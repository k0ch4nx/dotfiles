#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

main() (
    local system_result="${DOTFILES_SYSTEM_RESULT:-}"

    [[ "${system_result}" != *$'\n'* ]] || return 1
    [[ "${system_result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

    case "$(uname -s)" in
    Darwin)
        sudo -H /nix/var/nix/profiles/default/bin/nix-env \
            --profile /nix/var/nix/profiles/system \
            --set "${system_result}"

        sudo "${system_result}/sw/bin/darwin-rebuild" activate
        ;;
    Linux)
        local home_result="${DOTFILES_HOME_RESULT:-}"

        [[ "${home_result}" != *$'\n'* ]] || return 1
        [[ "${home_result}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

        sudo "${system_result}/bin/register-profile"
        "${home_result}/activate"
        sudo "${system_result}/bin/activate"
        ;;
    *)
        return 1
        ;;
    esac
)

main
