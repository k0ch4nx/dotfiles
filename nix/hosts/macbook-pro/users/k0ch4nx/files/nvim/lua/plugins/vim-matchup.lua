---@module "lazy"
---@type LazySpec
return {
    ---@module "match-up"
    "andymass/vim-matchup",
    dependencies = {
        ---@module "nvim-treesitter"
        "neovim-treesitter/nvim-treesitter",
    },
    ---@type matchup.Config
    opts = {},
    lazy = false,
}
