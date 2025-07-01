---@module "lazy"
---@type LazySpec
return {
    ---@module "which-key"
    "folke/which-key.nvim",
    ---@type wk.Opts
    opts = {
        win = {
            row = -2,
            border = "rounded",
            wo = {
                winblend = vim.o.winblend,
            },
        },
    },
    event = "VeryLazy",
}
