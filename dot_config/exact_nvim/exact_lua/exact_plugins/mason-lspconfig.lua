---@module "lazy"
---@type LazySpec
return {
    ---@module "mason-lspconfig"
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        "williamboman/mason.nvim",
    },
    opts = function()
        local lsp_config_dir = vim.fn.stdpath("config") .. "/after/lsp"

        local ensure_installed = vim.tbl_map(
            function(fname) return fname:gsub("%.lua$", "") end,
            vim.fn.readdir(lsp_config_dir)
        )

        ---@type MasonLspconfigSettings
        ---@diagnostic disable-next-line: missing-fields
        return {
            ensure_installed = ensure_installed,
        }
    end,
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
}
