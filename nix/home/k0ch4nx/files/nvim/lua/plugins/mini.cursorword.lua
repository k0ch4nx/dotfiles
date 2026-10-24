---@module "lazy"
---@type LazySpec
return {
    ---@module "mini.cursorword"
    "echasnovski/mini.cursorword",
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
    opts = function(self)
        return {}
    end,
}
