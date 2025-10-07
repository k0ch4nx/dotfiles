---@module "lazy"
---@type LazySpec
return {
    ---@module "mason-null-ls"
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
        "nvimtools/none-ls.nvim",
        "williamboman/mason.nvim",
    },
    opts = function(self, opts) ---@diagnostic disable-line: unused-local
        ---@type MasonNullLsMethods
        ---@diagnostic disable-next-line: missing-fields
        return {
            ensure_installed = {
                "buildifier",
                "hadolint",
                "shellcheck",
                "shfmt",
                "terraform",
                "yamlfmt",
                "yamllint",
            },
            handlers = {
                function(source_name, methods)
                    require(require("lazy.core.loader").get_main(self)).default_setup(source_name, methods)
                end,
            },
        }
    end,
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
}
