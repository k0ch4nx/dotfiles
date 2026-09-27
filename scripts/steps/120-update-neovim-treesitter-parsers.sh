#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

[[ "${DOTFILES_SKIP_UPDATES:-}" == "1" ]] && return 0

function main() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local treesitter = require("nvim-treesitter")
local parsers = treesitter.get_installed()
local ok = treesitter.update(parsers):wait()
if not ok then
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

main
