---@module "lazy"
---@type LazySpec
return {
    ---@module "toggleterm"
    "akinsho/toggleterm.nvim",
    ---@type ToggleTermConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        size = function(term)
            if term.direction == "horizontal" then
                return vim.o.lines * 0.3
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,
        shade_terminals = false,
        direction = "horizontal",
        auto_scroll = false,
        float_opts = {
            border = "rounded",
            winblend = vim.o.winblend,
        },
    },
    event = "VeryLazy",
}
