#!/usr/bin/env bash

set -euo pipefail

nvim --headless -c 'lua local ok = require("nvim-treesitter").install("all"):wait(); if not ok then print("nvim-treesitter install failed"); vim.cmd("cquit") else vim.cmd("qa") end'
nvim --headless -c 'lua local ok = require("nvim-treesitter").update():wait(); if not ok then print("nvim-treesitter update failed"); vim.cmd("cquit") else vim.cmd("qa") end'
