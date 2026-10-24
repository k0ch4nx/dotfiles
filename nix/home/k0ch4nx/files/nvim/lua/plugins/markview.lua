---@module "lazy"
---@type LazySpec
return {
    ---@module "markview"
    "OXY2DEV/markview.nvim",
    event = "VeryLazy",
    ---@type markview.config
    opts = {
        renderers = {
            markdown_table = function(buffer, item)
                require("markview-smart-tables").render(buffer, item)
            end,
        },
    },
}
