---@module "lazy"
---@type LazySpec
return {
    ---@module "treesitter-context"
    "nvim-treesitter/nvim-treesitter-context",
    ---@type TSContext.UserConfig
    opts = {},
    event = "VeryLazy",
}
