---@module "lazy"
---@type LazySpec
return {
    ---@module "lspconfig"
    "neovim/nvim-lspconfig",
    optional = true,
    config = function()
        ---@type table<string, fun(config: vim.lsp.Config): vim.lsp.Config>
        local overrides = {
            oxfmt = function(config)
                local excluded = { json = true, jsonc = true, json5 = true }

                return {
                    filetypes = vim.iter(config.filetypes):filter(function(filetype)
                        return not excluded[filetype]
                    end):totable(),
                }
            end,
        }

        for server, override in pairs(overrides) do
            local config = vim.lsp.config[server]
            if config then
                vim.lsp.config(server, override(config))
            end
        end
    end,
}
