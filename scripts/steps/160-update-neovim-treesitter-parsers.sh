#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != "true" ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        return
    fi

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

main
