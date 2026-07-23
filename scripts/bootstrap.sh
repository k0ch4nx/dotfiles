#!/usr/bin/env bash

set -xeuo pipefail

function is_github_actions() {
    [[ "${GITHUB_ACTIONS:-}" == "true" ]]
}

function is_darwin() {
    [[ "$(uname -s)" == "Darwin" ]]
}

function is_wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] &&
        grep -qi microsoft /proc/sys/kernel/osrelease
}

function load_nix_profile() {
    local profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

    if [[ -r "${profile}" ]]; then
        # shellcheck disable=SC1090
        source "${profile}"
    fi
}

function install_nix() {
    load_nix_profile

    if command -v nix >/dev/null 2>&1; then
        return
    fi

    if is_darwin; then
        curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --yes
    elif is_wsl; then
        curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
    else
        exit 1
    fi

    load_nix_profile
    command -v nix >/dev/null 2>&1
}

function main() {
    local nix_config

    if is_github_actions; then
        exit 1
    fi

    readonly DOTFILES_USER="k0ch4nx"

    if is_darwin; then
        [[ "$(uname -m)" == "arm64" ]] || exit 1

        readonly DOTFILES_HOST="macbook-pro"
        readonly GHQ_ROOT="${HOME}/Developer"
    elif is_wsl; then
        readonly DOTFILES_HOST="ubuntu-wsl"
        readonly GHQ_ROOT="${HOME}/src"
    else
        exit 1
    fi

    export DOTFILES_USER DOTFILES_HOST GHQ_ROOT

    set +x
    nix_config="${NIX_CONFIG:-}"
    if [[ -n "${nix_config}" ]]; then
        nix_config+=$'\n'
    fi
    nix_config+="extra-experimental-features = nix-command flakes"
    NIX_CONFIG="${nix_config}"
    export NIX_CONFIG
    set -x

    install_nix

    nix \
        run \
        nixpkgs#ghq \
        -- \
        get \
        https://github.com/k0ch4nx/dotfiles.git

    readonly DOTFILES_DIR="${GHQ_ROOT}/github.com/${DOTFILES_USER}/dotfiles"
    export DOTFILES_DIR

    [[ -f "${DOTFILES_DIR}/flake.nix" ]] || exit 1

    source "${DOTFILES_DIR}/scripts/steps/020-install-nix.sh"
    source "${DOTFILES_DIR}/scripts/steps/060-ensure-host-identity.sh"
    source "${DOTFILES_DIR}/scripts/steps/070-update-flake-lock.sh"
    source "${DOTFILES_DIR}/scripts/steps/080-rekey-secrets.sh"
    source "${DOTFILES_DIR}/scripts/steps/085-prepare-nix-cache.sh"
    source "${DOTFILES_DIR}/scripts/steps/090-build-nix-configuration.sh"
    source "${DOTFILES_DIR}/scripts/steps/100-activate-nix-configuration.sh"
    source "${DOTFILES_DIR}/scripts/steps/110-configure-wsl-login-shell.sh"
    source "${DOTFILES_DIR}/scripts/steps/120-push-nix-cache.sh"
    source "${DOTFILES_DIR}/scripts/steps/130-update-rust.sh"
    source "${DOTFILES_DIR}/scripts/steps/140-update-neovim-plugins.sh"
    source "${DOTFILES_DIR}/scripts/steps/150-install-neovim-treesitter-parsers.sh"
    source "${DOTFILES_DIR}/scripts/steps/160-update-neovim-treesitter-parsers.sh"
    source "${DOTFILES_DIR}/scripts/steps/170-update-neovim-mason-packages.sh"
    source "${DOTFILES_DIR}/scripts/steps/180-update-neovim-codediff.sh"
    source "${DOTFILES_DIR}/scripts/steps/190-update-github-cli-extensions.sh"
    source "${DOTFILES_DIR}/scripts/steps/200-update-macos.sh"
    source "${DOTFILES_DIR}/scripts/steps/210-update-ubuntu.sh"
    source "${DOTFILES_DIR}/scripts/steps/220-collect-nix-garbage.sh"
}

main
