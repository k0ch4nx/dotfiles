#!/usr/bin/env bash

set -euo pipefail

readonly user="k0ch4nx"
readonly domain="github.com"
readonly repo="dotfiles"

host=""
ghq_root=""
dotfiles_dir=""

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

function detect_platform() {
    if is_darwin; then
        [[ "$(uname -m)" == "arm64" ]] || exit 1

        host="macbook-pro"
        ghq_root="${HOME}/Developer"
    elif is_wsl; then
        host="ubuntu-wsl"
        ghq_root="${HOME}/src"
    else
        exit 1
    fi
}

function install_nix() {
    if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    if command -v nix >/dev/null 2>&1; then
        return
    fi

    if is_darwin; then
        if ! is_github_actions; then
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
        else
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --yes
        fi
    elif is_wsl; then
        if ! is_github_actions; then
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
        else
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon --yes
        fi
    else
        return
    fi

    if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    if ! command -v nix >/dev/null 2>&1; then
        exit 1
    fi
}

function prepare_dotfiles() {
    if is_github_actions; then
        dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
        return
    fi

    GHQ_ROOT="${ghq_root}" \
        nix \
        --extra-experimental-features 'nix-command flakes' \
        run nixpkgs#ghq \
        -- \
        get "${user}/${repo}"

    dotfiles_dir="${ghq_root}/${domain}/${user}/${repo}"
}

function update_nix() {
    if is_github_actions; then
        return
    fi

    (
        cd "${dotfiles_dir}"

        nix \
            --extra-experimental-features 'nix-command flakes' \
            flake update
    )
}

function run_agenix_rekey() {
    local system

    system="$(
        nix \
            --extra-experimental-features 'nix-command flakes' \
            eval \
            --raw \
            --impure \
            --expr 'builtins.currentSystem'
    )"

    if is_github_actions; then
        nix \
            --extra-experimental-features 'nix-command flakes' \
            run \
            --impure \
            --no-update-lock-file \
            "${dotfiles_dir}#agenix-rekey.${system}.rekey" \
            -- \
            --dummy
    else
        nix \
            --extra-experimental-features 'nix-command flakes' \
            run \
            --impure \
            --no-update-lock-file \
            "${dotfiles_dir}#agenix-rekey.${system}.rekey"
    fi
}

function build_nix() {
    (
        cd "${dotfiles_dir}"

        if is_darwin; then
            nix \
                --extra-experimental-features 'nix-command flakes' \
                build \
                --impure \
                --no-update-lock-file \
                ".#darwinConfigurations.${host}.config.system.build.toplevel"
        elif is_wsl; then
            nix \
                --extra-experimental-features 'nix-command flakes' \
                build \
                --impure \
                --no-update-lock-file \
                ".#homeConfigurations.\"${user}@${host}\".activationPackage"
        fi
    )
}

function apply_nix() {
    if is_github_actions; then
        return
    fi

    if is_darwin; then
        if command -v darwin-rebuild >/dev/null 2>&1; then
            sudo darwin-rebuild switch \
                --impure \
                --flake "${dotfiles_dir}#${host}"
        else
            sudo nix \
                --extra-experimental-features 'nix-command flakes' \
                run nix-darwin/master#darwin-rebuild \
                -- \
                switch \
                --impure \
                --flake "${dotfiles_dir}#${host}"
        fi
    elif is_wsl; then
        if command -v home-manager >/dev/null 2>&1; then
            home-manager switch \
                --flake "${dotfiles_dir}#${user}@${host}"
        else
            "${dotfiles_dir}/result/activate"
        fi
    fi
}

function update_neovim_plugins() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok, err = pcall(vim.cmd, "Lazy! sync")
if not ok then
    print(err)
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

function install_neovim_treesitter_parsers() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok = require("nvim-treesitter").install("all"):wait()
if not ok then
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

function update_neovim_treesitter_parsers() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok = require("nvim-treesitter").update():wait()
if not ok then
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

function update_neovim_mason_packages() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok, err = pcall(vim.cmd, "MasonInstallAll")
if not ok then
    print(err)
    vim.cmd("cquit")
else
    vim.cmd("MasonLock")
    vim.cmd("qa")
end
LUA
}

function update_neovim_codediff() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok, err = pcall(require("codediff.core.installer").install)
if not ok then
    print(err)
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

function update_github_cli_extensions() {
    gh extension upgrade --all
}

function update_rust() {
    rustup update
}

function update_macos() {
    if is_github_actions || ! is_darwin; then
        return
    fi

    softwareupdate --install --all
}

function update_apt() {
    if is_github_actions || ! is_wsl; then
        return
    fi

    sudo apt update
    sudo apt full-upgrade -y
    sudo apt autoremove --purge -y
    sudo do-release-upgrade
}

function main() {
    detect_platform
    install_nix
    prepare_dotfiles

    update_nix
    run_agenix_rekey
    build_nix
    apply_nix

    if ! is_github_actions; then
        update_rust
        update_neovim_plugins
        install_neovim_treesitter_parsers
        update_neovim_treesitter_parsers
        update_neovim_mason_packages
        update_neovim_codediff
        update_github_cli_extensions
    fi

    update_macos
    update_apt
}

main
