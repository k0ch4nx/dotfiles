---@module "lazy"
---@type LazySpec
return {
    ---@module "null-ls"
    "nvimtools/none-ls.nvim",
    opts = function()
        return {
            sources = {
                require("null-ls").builtins.formatting.nixfmt,
            },
        }
    end,
    optional = true,
}
