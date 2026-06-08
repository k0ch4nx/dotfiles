---@module "lazy"
---@type LazySpec
return {
    "delphinus/md-render.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "delphinus/budoux.lua",
    },
    event = "VeryLazy",
}
