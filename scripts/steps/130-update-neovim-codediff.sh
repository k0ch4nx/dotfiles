#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
local ok, err = pcall(function()
    require("lazy").load({ plugins = { "codediff.nvim" } })
    local installer = require("codediff.core.installer.libvscode_diff")
    local success, install_err = installer.install()
    if not success then
        error(install_err)
    end
end)

if not ok then
    io.stderr:write(tostring(err) .. "\n")
    vim.cmd("cquit 1")
else
    vim.cmd("qa")
end
LUA
}

main
