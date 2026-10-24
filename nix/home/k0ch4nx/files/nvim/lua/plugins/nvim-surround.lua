---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-surround"
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {
        move_cursor = "sticky",
    },
}
