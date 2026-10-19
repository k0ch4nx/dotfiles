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
            ts_ls = function(config)
                local vue_typescript_plugin = vim.fn.stdpath("data")
                    .. "/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin"

                if vim.fn.isdirectory(vue_typescript_plugin) == 0 then
                    return {}
                end

                return {
                    filetypes = vim.list_extend(vim.deepcopy(config.filetypes or {}), { "vue" }),
                    init_options = {
                        plugins = {
                            {
                                name = "@vue/typescript-plugin",
                                location = vue_typescript_plugin,
                                languages = { "vue" },
                            },
                        },
                    },
                }
            end,
        }

        for server, override in pairs(overrides) do
            local config = vim.lsp.config[server]
            if config then
                vim.lsp.config(server, override(config))
            end
        end

        local bashls = vim.lsp.config["bashls"]

        if bashls then
            vim.lsp.config("bashls", {
                filetypes = vim.list_extend(vim.deepcopy(bashls.filetypes or {}), { "zsh" }),
            })
        end
    end,
}
