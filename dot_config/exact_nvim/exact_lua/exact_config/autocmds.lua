-- https://github.com/neovim/neovim/issues/4396#issuecomment-1377191592
vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
        vim.opt.guicursor = ""
        vim.fn.chansend(vim.v.stderr, "\x1b[ q")
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() == 0 then
            return
        end

        local arg0 = vim.fn.argv(0)

        if vim.fn.isdirectory(arg0) == 1 then
            vim.cmd.cd(arg0)
        end
    end,
})

-- https://minerva.mamansoft.net/Notes/ファイルが変更されたら自動で再読み込み+(Neovim)
vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
    pattern = "*",
    command = "checktime",
})
