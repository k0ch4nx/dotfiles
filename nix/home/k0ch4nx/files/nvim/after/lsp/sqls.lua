---@type vim.lsp.Config
return {
    ---@param client vim.lsp.Client
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
}
