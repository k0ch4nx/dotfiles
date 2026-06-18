---@module "lazy"
---@type LazySpec
return {
    ---@module "edgy"
    "folke/edgy.nvim",
    ---@type Edgy.Config
    opts = {
        left = {
            {
                ft = "snacks_layout_box",
                filter = function(_, win)
                    return vim.api.nvim_win_get_config(win).relative == ""
                end,
                title = "Explorer",
                open = function()
                    Snacks.explorer.open()
                end,
            },
            {
                ft = "dapui_scopes",
                title = "Variables",
            },
            {
                ft = "dapui_watches",
                title = "Watch",
            },
            {
                ft = "dapui_stacks",
                title = "Call Stack",
            },
            {
                ft = "dapui_breakpoints",
                title = "Breakpoints",
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
                filter = function(_, win)
                    return vim.api.nvim_win_get_config(win).relative == ""
                end,
            },
            {
                ft = "dapui_console",
                title = "Debug Console",
            },
            {
                ft = "dap-repl",
                title = "DAP REPL",
            },
        },
        options = {
            left = { size = 0.2 },
            bottom = { size = 0.35 },
        },
        animate = {
            enabled = false,
        },
    },
    event = "VeryLazy",
}
