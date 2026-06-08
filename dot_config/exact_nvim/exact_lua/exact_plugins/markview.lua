---@module "lazy"
---@type LazySpec
return {
    ---@module "markview"
    "OXY2DEV/markview.nvim",
    init = function()
        vim.g.markview_blink_loaded = true
    end,
    opts = {},
    event = "VeryLazy",
}
