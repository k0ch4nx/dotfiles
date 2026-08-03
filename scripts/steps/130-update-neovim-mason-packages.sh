#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    nvim \
        --headless \
        -c 'luafile -' <<'LUA'
vim.cmd("MasonLockRestore")

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

main
