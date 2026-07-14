---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-treesitter-textobjects"
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = {
        ---@module "nvim-treesitter"
        "neovim-treesitter/nvim-treesitter",
    },
    init = function()
        vim.g.no_plugin_maps = true
    end,
    ---@type TSTextObjects.Config
    opts = {},
    keys = {
        {
            "am",
            function()
                require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
            end,
            mode = { "x", "o" },
        },
        {
            "im",
            function()
                require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
            end,
            mode = { "x", "o" },
        },
        {
            "ac",
            function()
                require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
            end,
            mode = { "x", "o" },
        },
        {
            "ic",
            function()
                require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
            end,
            mode = { "x", "o" },
        },
    },
    branch = "main",
    event = "VeryLazy",
}
