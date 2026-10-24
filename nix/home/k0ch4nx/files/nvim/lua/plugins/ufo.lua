---@module "lazy"
---@type LazySpec
return {
    ---@module "ufo"
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    event = { "VeryLazy" },
    opts = function(self, opts) ---@diagnostic disable-line: unused-local
        return {
            preview = {
                win_config = {
                    border = { "", "─", "", "", "", "─", "", "" },
                    winblend = vim.o.winblend,
                },
            },
        }
    end,
}
