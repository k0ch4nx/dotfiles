---@module "lazy"
---@type LazySpec
return {
    ---@module "edgy"
    "folke/edgy.nvim",
    ---@type Edgy.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        left = {
            {
                title = "Explorer",
                ft = "snacks_explorer",
                filter = function(buf, win)
                    return vim.api.nvim_win_get_config(win).relative == ""
                end,
                pinned = true,
            },
        },
        bottom = {
            {
                ft = "help",
                filter = function(buf)
                    return vim.bo[buf].buftype == "help"
                end,
            },
            {
                ft = "toggleterm",
                ---@diagnostic disable-next-line: unused-local
                filter = function(buf, win)
                    return vim.api.nvim_win_get_config(win).relative == ""
                end,
            },
        },
        options = {
            left = { size = 0.2 },
            bottom = { size = 0.4 },
        },
        animate = {
            enabled = false,
        },
    },
    event = "VeryLazy",
}
