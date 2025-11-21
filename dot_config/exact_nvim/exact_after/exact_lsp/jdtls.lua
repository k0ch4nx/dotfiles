---@type vim.lsp.Config
return {
    -- https://github.com/neovim/nvim-lspconfig/issues/2970
    handlers = {
        ["language/status"] = function(_, result, ctx, _)
            if result.type == "ServiceReady" then
                for _, bufnr in ipairs(vim.lsp.get_buffers_by_client_id(ctx.client_id)) do
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr });
                end
            end
        end,
    },
}
