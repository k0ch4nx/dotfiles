#!/usr/bin/env bash

set -euo pipefail

nvim --headless -c 'lua local ok, err = pcall(vim.cmd, "MasonInstallAll"); if not ok then print(err); vim.cmd("cquit") else vim.cmd("MasonLock"); vim.cmd("qa") end'
