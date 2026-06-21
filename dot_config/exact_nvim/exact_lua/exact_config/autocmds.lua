vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() == 0 then
            return
        end

        local arg0 = vim.fn.argv(0)

        if vim.fn.isdirectory(arg0) == 1 then
            vim.api.nvim_set_current_dir(arg0)
        end
    end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
    pattern = "*",
    command = "checktime",
})
