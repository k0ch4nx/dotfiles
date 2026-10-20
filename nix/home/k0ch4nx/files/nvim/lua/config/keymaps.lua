vim.keymap.set({ "n", "v" }, "j", function()
    return vim.v.count == 0 and "gj" or "j"
end, { expr = true })

vim.keymap.set({ "n", "v" }, "k", function()
    return vim.v.count == 0 and "gk" or "k"
end, { expr = true })

vim.keymap.set({ "n", "v" }, "<Leader>f", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
