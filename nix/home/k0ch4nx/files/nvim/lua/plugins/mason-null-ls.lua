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
                "checkstyle",
                "csharpier",
                "hadolint",
                "npm-groovy-lint",
                "oxfmt",
                "oxlint",
                "palantir-java-format",
                "shellcheck",
                "shfmt",
                "statix",
                "terraform",
                "trivy",
                "yamlfmt",
                "yamllint",
            },
            handlers = {
                function(source_name, methods)
                    require(require("lazy.core.loader").get_main(self)).default_setup(source_name, methods)
                end,
                npm_groovy_lint = function(source_name, methods)
                    local null_ls = require("null-ls")
                    for _, method in ipairs(methods) do
                        null_ls.register(null_ls.builtins[method][source_name].with({
                            filetypes = { "groovy", "Jenkinsfile" },
                        }))
                    end
                end,
            },
        }
    end,
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
}
