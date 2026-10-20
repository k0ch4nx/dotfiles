---@module "lazy"
---@type LazySpec
return {
    "nvimtools/none-ls.nvim",
    ft = { "nix" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
            sources = {
                -- Code actions only: formatting stays in conform, diagnostics in nvim-lint.
                null_ls.builtins.code_actions.statix.with({
                    timeout = 3000,
                    runtime_condition = function()
                        if vim.fn.executable("statix") == 1 then
                            return true
                        end

                        vim.notify_once(
                            "statix unavailable; showing LSP actions only",
                            vim.log.levels.WARN
                        )

                        return false
                    end,
                }),
            },
        })
    end,
}
