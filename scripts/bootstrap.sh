#!/usr/bin/env bash

set -euo pipefail

readonly user="k0ch4nx"
readonly domain="github.com"
readonly repo="dotfiles"

host=""
ghq_root=""
dotfiles_dir=""
force_rekey=false

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

function trust_github_actions_runner() {
    if ! is_github_actions || ! is_darwin; then
        return
    fi

    local trusted_user
    trusted_user="$(id -un)"

    printf 'extra-trusted-users = %s\n' "${trusted_user}" |
        sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo launchctl kickstart -k system/org.nixos.nix-daemon
}

function run_age_keygen() {
    if command -v rage-keygen >/dev/null 2>&1; then
        rage-keygen "$@"
    else
        nix \
            --extra-experimental-features 'nix-command flakes' \
            shell nixpkgs#rage \
            -c rage-keygen \
            "$@"
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

function ensure_host_identity() {
    if is_github_actions; then
        return
    fi

    local identity_dir="${dotfiles_dir}/secrets/hosts"
    local identity_name="${host}-${user}"
    local private_key="${identity_dir}/${identity_name}-key.txt"
    local public_key_file="${identity_dir}/${identity_name}.pub"
    local public_key

    mkdir -p "${identity_dir}"

    if [[ ! -f "${private_key}" ]]; then
        run_age_keygen -o "${private_key}"
        force_rekey=true
    fi

    public_key="$(run_age_keygen -y "${private_key}")"

    if [[ ! -f "${public_key_file}" ]] || [[ "$(<"${public_key_file}")" != "${public_key}" ]]; then
        printf '%s\n' "${public_key}" >"${public_key_file}"
        force_rekey=true
    fi
}

function update_nix() {
    if is_github_actions; then
        return
    fi

    (
        cd "${dotfiles_dir}"

        if [[ "${GH_TOKEN+x}" != x ]]; then
            exec nix \
                --extra-experimental-features 'nix-command flakes' \
                flake update
        fi

        set +x
        local nix_config="${NIX_CONFIG:-}"
        if [[ -n "${nix_config}" ]]; then
            nix_config+=$'\n'
        fi
        nix_config+="access-tokens = github.com=${GH_TOKEN}"

        NIX_CONFIG="${nix_config}" exec nix \
            --extra-experimental-features 'nix-command flakes' \
            flake update
    )
}

function run_agenix_rekey() {
    (
        cd "${dotfiles_dir}"

        local nix_config="${NIX_CONFIG:-}"
        local plugin
        local system

        if [[ -n "${nix_config}" ]]; then
            nix_config+=$'\n'
        fi
        nix_config+="extra-experimental-features = nix-command flakes"

        plugin="$(
            NIX_CONFIG="${nix_config}" nix \
                --extra-experimental-features 'nix-command flakes' \
                build \
                --no-link \
                --print-out-paths \
                'nixpkgs#age-plugin-yubikey^out'
        )"

        system="$(
            NIX_CONFIG="${nix_config}" nix \
                --extra-experimental-features 'nix-command flakes' \
                eval \
                --raw \
                --impure \
                --expr 'builtins.currentSystem'
        )"

        if is_github_actions; then
            PATH="${plugin}/bin:${PATH}" \
                NIX_CONFIG="${nix_config}" nix \
                --extra-experimental-features 'nix-command flakes' \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey" \
                -- \
                --dummy
        elif [[ "${force_rekey}" == true ]]; then
            PATH="${plugin}/bin:${PATH}" \
                NIX_CONFIG="${nix_config}" nix \
                --extra-experimental-features 'nix-command flakes' \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey" \
                -- \
                --force
        else
            PATH="${plugin}/bin:${PATH}" \
                NIX_CONFIG="${nix_config}" nix \
                --extra-experimental-features 'nix-command flakes' \
                run \
                --impure \
                --no-update-lock-file \
                "path:.#agenix-rekey.${system}.rekey"
        fi
    )
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
                "path:.#darwinConfigurations.${host}.config.system.build.toplevel"
        elif is_wsl; then
            nix \
                --extra-experimental-features 'nix-command flakes' \
                build \
                --impure \
                --no-update-lock-file \
                "path:.#homeConfigurations.\"${user}@${host}\".activationPackage"
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
                --flake "path:${dotfiles_dir}#${host}"
        else
            sudo nix \
                --extra-experimental-features 'nix-command flakes' \
                run nix-darwin/master#darwin-rebuild \
                -- \
                switch \
                --impure \
                --flake "path:${dotfiles_dir}#${host}"
        fi
    elif is_wsl; then
        if command -v home-manager >/dev/null 2>&1; then
            home-manager switch \
                --impure \
                --flake "path:${dotfiles_dir}#${user}@${host}"
        else
            "${dotfiles_dir}/result/activate"
        fi
    fi
}

function push_nix_cache() {
    if is_github_actions; then
        return
    fi

    nix \
        --extra-experimental-features 'nix-command flakes' \
        run \
        --impure \
        --no-update-lock-file \
        "path:${dotfiles_dir}#cache-push"
}

function collect_nix_garbage() {
    if is_github_actions; then
        return
    fi

    local gc_command
    gc_command="$(command -v nix-collect-garbage)"

    "${gc_command}" \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false

    sudo "${gc_command}" \
        --delete-older-than 1d \
        --option keep-outputs false \
        --option keep-derivations false
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
local treesitter = require("nvim-treesitter")
local unavailable = { problog = true, prolog = true }
local parsers = vim.tbl_filter(function(parser)
    return not unavailable[parser]
end, treesitter.get_available())
local ok = treesitter.install(parsers):wait()
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
local treesitter = require("nvim-treesitter")
local unavailable = { problog = true, prolog = true }
local parsers = vim.tbl_filter(function(parser)
    return not unavailable[parser]
end, treesitter.get_installed())
local ok = treesitter.update(parsers):wait()
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
    if ! is_github_actions; then
        set -x
    fi

    detect_platform
    install_nix
    trust_github_actions_runner
    prepare_dotfiles
    ensure_host_identity

    update_nix
    run_agenix_rekey
    build_nix
    apply_nix
    push_nix_cache

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
    collect_nix_garbage
}

main
