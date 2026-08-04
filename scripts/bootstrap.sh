#!/usr/bin/env bash

set -xeuo pipefail

function main() {
    readonly DOTFILES_USER="k0ch4nx"

    case "$(uname -s)" in
    Darwin)
        [[ "$(uname -m)" == "arm64" ]] || exit 1

        readonly DOTFILES_HOST="macbook-pro"
        readonly GHQ_ROOT="${HOME}/Developer"
        ;;
    Linux)
        readonly DOTFILES_HOST="ubuntu-wsl"
        readonly GHQ_ROOT="${HOME}/src"
        ;;
    *)
        exit 1
        ;;
    esac

    export DOTFILES_USER
    export DOTFILES_HOST
    export GHQ_ROOT

    readonly DOTFILES_DIR="${GHQ_ROOT}/github.com/${DOTFILES_USER}/dotfiles"
    export DOTFILES_DIR

    if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]:-}" ]]; then
        source "${DOTFILES_DIR}/scripts/steps/010-install-nix.sh"
    else
        # shellcheck disable=SC1090
        source <(curl -fsSL "https://github.com/k0ch4nx/dotfiles/raw/refs/heads/main/scripts/steps/010-install-nix.sh")
    fi

    nix \
        run \
        nixpkgs#ghq \
        -- \
        get \
        https://github.com/${DOTFILES_USER}/dotfiles.git

    source "${DOTFILES_DIR}/scripts/steps/020-ensure-yubikey-identity.sh"
    source "${DOTFILES_DIR}/scripts/steps/030-prepare-terraform-auth.sh"
    source "${DOTFILES_DIR}/scripts/steps/040-prepare-nix-cache.sh"
    source "${DOTFILES_DIR}/scripts/steps/050-update-flake-lock.sh"
    source "${DOTFILES_DIR}/scripts/steps/060-build-nix-configuration.sh"
    source "${DOTFILES_DIR}/scripts/steps/070-activate-nix-configuration.sh"
    source "${DOTFILES_DIR}/scripts/steps/080-push-nix-cache.sh"
    source "${DOTFILES_DIR}/scripts/steps/081-touch-nix-cache.sh"
    source "${DOTFILES_DIR}/scripts/steps/090-update-rust.sh"
    source "${DOTFILES_DIR}/scripts/steps/100-update-neovim-plugins.sh"
    source "${DOTFILES_DIR}/scripts/steps/110-install-neovim-treesitter-parsers.sh"
    source "${DOTFILES_DIR}/scripts/steps/120-update-neovim-treesitter-parsers.sh"
    source "${DOTFILES_DIR}/scripts/steps/130-update-neovim-mason-packages.sh"
    source "${DOTFILES_DIR}/scripts/steps/140-update-neovim-codediff.sh"
    source "${DOTFILES_DIR}/scripts/steps/150-update-macos.sh"
    source "${DOTFILES_DIR}/scripts/steps/160-update-ubuntu.sh"
    source "${DOTFILES_DIR}/scripts/steps/170-collect-nix-garbage.sh"
}

main
