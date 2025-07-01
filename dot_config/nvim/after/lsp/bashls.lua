---@type vim.lsp.Config
return {
    filetypes = vim.tbl_deep_extend("force", require("lspconfig.configs.bashls").default_config.filetypes, { "zsh" }),
}
