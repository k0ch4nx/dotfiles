---@module "lazy"
---@type LazySpec
return {
    ---@module "hardtime"
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
        max_count = 5,
        disable_mouse = false,
    },
    lazy = false,
}
