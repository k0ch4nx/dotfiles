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
local ok, err = pcall(require("codediff.core.installer").install)
if not ok then
    print(err)
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
}

main
