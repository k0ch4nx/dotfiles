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
                    if vim.api.nvim_win_get_config(win).relative ~= "" then
                        return false
                    end

                    local Snacks = rawget(_G, "Snacks")
                    if not Snacks or not Snacks.picker then
                        return false
                    end

                    local pickers = Snacks.picker.get({ source = "explorer" }) or {}

                    return vim.iter(pickers):any(function(picker)
                        local wins = picker.layout and picker.layout.wins or {}

                        return vim.iter(pairs(wins)):any(function(_, layout_win)
                            return layout_win.win == win
                        end)
                    end)
                end,
                title = "Explorer",
                wo = {
                    winbar = false,
                },
            },
            {
                ft = "codediff-explorer",
                title = "CodeDiff Explorer",
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
                ft = "dap-view",
                title = "DAP View",
            },
            {
                ft = "dap-repl",
                title = "DAP View",
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
