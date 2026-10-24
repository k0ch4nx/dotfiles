---@module "lazy"
---@type LazySpec
return {
    ---@module "md-render"
    "delphinus/md-render.nvim",
    dependencies = {
        ---@module "nvim-web-devicons"
        "nvim-tree/nvim-web-devicons",
        ---@module "budoux"
        "delphinus/budoux.lua",
    },
    event = { "VeryLazy" },
}
