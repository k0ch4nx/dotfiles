---@module "lazy"
---@type LazySpec
return {
    ---@module "match-up"
    "andymass/vim-matchup",
    dependencies = {
        ---@module "nvim-treesitter"
        "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    ---@type matchup.Config
    opts = {},
}
