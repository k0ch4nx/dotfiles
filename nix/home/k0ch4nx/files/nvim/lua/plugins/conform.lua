---@module "lazy"
---@type LazySpec
return {
    ---@module "conform"
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    event = { "BufWritePre" },
    opts = {
        formatters = {
            npm_groovy_lint = {
                command = "npm-groovy-lint",
                args = { "--failon", "none", "--format", "-" },
                stdin = true,
            },
        },
        -- `mason-null-ls` used to provide these through none-ls.
        -- LSP formatting is used as a fallback for every other filetype.
        formatters_by_ft = {
            bzl = { "buildifier" },
            cs = { "csharpier" },
            groovy = { "npm_groovy_lint" },
            Jenkinsfile = { "npm_groovy_lint" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            sql = { "sqruff" },
            terraform = { "terraform_fmt" },
            tf = { "terraform_fmt" },
            ["terraform-vars"] = { "terraform_fmt" },
            yaml = { "yamlfmt" },
            nix = { "nixfmt" },
        },
    },
}
