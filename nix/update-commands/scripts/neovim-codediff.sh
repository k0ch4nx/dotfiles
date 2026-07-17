nvim --headless -c 'lua local ok, err = pcall(require("codediff.core.installer").install); if not ok then print(err); vim.cmd("cquit") else vim.cmd("qa") end'
