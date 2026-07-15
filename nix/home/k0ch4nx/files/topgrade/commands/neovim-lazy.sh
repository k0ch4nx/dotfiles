#!/usr/bin/env bash

set -euo pipefail

nvim --headless -c 'lua local ok, err = pcall(vim.cmd, "Lazy! sync"); if not ok then print(err); vim.cmd("cquit") else vim.cmd("qa") end'
