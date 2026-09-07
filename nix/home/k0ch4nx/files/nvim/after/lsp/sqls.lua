---@type vim.lsp.Config
return {
    ---@type vim.lsp.client.on_attach_cb
    on_attach = function(client, bufnr)
        if vim.bo[bufnr].buftype == "terminal" then
            client:stop(true)
            return
        end

        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        if client:supports_method("textDocument/inlayHint", bufnr) or client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
}
