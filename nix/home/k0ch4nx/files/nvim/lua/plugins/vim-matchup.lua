---@module "lazy"
---@type LazySpec
return {
    ---@module "match-up"
    "andymass/vim-matchup",
    dependencies = {
        ---@module "nvim-treesitter"
        "nvim-treesitter/nvim-treesitter",
    },
    ---@type matchup.Config
    opts = {},
    lazy = false,
}
