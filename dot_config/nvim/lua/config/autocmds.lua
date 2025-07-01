-- https://github.com/neovim/neovim/issues/4396#issuecomment-1377191592
vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
        vim.opt.guicursor = ""
        vim.fn.chansend(vim.v.stderr, "\x1b[ q")
    end,
})

-- https://minerva.mamansoft.net/Notes/ファイルが変更されたら自動で再読み込み+(Neovim)
vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
    pattern = "*",
    command = "checktime",
})
