---@module "lazy"
---@type LazySpec
return {
    ---@module "treesitter-context"
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    ---@type TSContext.UserConfig
    opts = {},
}
