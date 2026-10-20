---@module "lazy"
---@type LazySpec
return {
    ---@module "lspconfig"
    "neovim/nvim-lspconfig",
    config = function()
        local nix = require("util").nix_paths()

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
                local vue_typescript_plugin = nix.vue_typescript_plugin

                if not vue_typescript_plugin or vim.fn.isdirectory(vue_typescript_plugin) == 0 then
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

        if nix.rust_analyzer then
            vim.lsp.config("rust_analyzer", {
                cmd = { nix.rust_analyzer },
            })
        end

        vim.lsp.enable({
            "astro",
            "bashls",
            "clangd",
            "cssls",
            "docker_compose_language_service",
            "dockerls",
            "eslint",
            "html",
            "jdtls",
            "jedi_language_server",
            "jsonls",
            "lua_ls",
            "nil_ls",
            "oxfmt",
            "oxlint",
            "powershell_es",
            "pyrefly",
            "roslyn_ls",
            "ruff",
            "rust_analyzer",
            "sqls",
            "starpls",
            "svelte",
            "tailwindcss",
            "terraformls",
            "tombi",
            "ts_ls",
            "typos_lsp",
            "vue_ls",
            "yamlls",
            "zls",
        })
    end,
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
}
