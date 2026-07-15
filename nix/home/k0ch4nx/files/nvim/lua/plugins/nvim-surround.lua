---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-surround"
    "kylechui/nvim-surround",
    opts = {
        move_cursor = "sticky",
    },
    event = "VeryLazy",
}
