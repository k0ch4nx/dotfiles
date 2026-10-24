---@module "lazy"
---@type LazySpec
return {
    ---@module "md-render"
    "delphinus/md-render.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "delphinus/budoux.lua",
    },
    event = { "VeryLazy" },
}
