vim.keymap.set({ "n", "v" }, "j", function()
    return vim.v.count == 0 and "gj" or "j"
end, { expr = true })

vim.keymap.set({ "n", "v" }, "k", function()
    return vim.v.count == 0 and "gk" or "k"
end, { expr = true })

vim.keymap.set({ "n", "v" }, "gf", function()
    vim.lsp.buf.format({ async = true })
end)
