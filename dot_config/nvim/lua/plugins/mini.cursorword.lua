---@module "lazy"
---@type LazySpec
return {
    ---@module "mini.cursorword"
    "echasnovski/mini.cursorword",
    opts = function(self)


        return { }
    end,
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
}
