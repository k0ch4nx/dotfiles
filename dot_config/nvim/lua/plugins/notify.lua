---@module "lazy"
---@type LazySpec
return {
    ---@module "notify"
    "rcarriga/nvim-notify",
    ---@type notify.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        max_width = function()
            return math.floor(vim.o.columns * 0.25)
        end,
        stages = {
            function(state)
                vim.iter(state.open_windows)
                    :filter(vim.api.nvim_win_is_valid)
                    :each(function(win)
                        local cfg = vim.api.nvim_win_get_config(win)
                        cfg.row = cfg.row + state.message.height + 2
                        vim.api.nvim_win_set_config(win, cfg)
                    end)

                return {
                    relative = "editor",
                    row = 0,
                    col = vim.o.columns,
                    width = state.message.width,
                    height = state.message.height,
                    style = "minimal",
                }
            end,
            function(state, win)
                local stages_util = require("notify.stages.util")

                return {
                    time = true,
                    row = stages_util.slot_after_previous(win, state.open_windows, stages_util.DIRECTION.TOP_DOWN),
                }
            end,
        },
        render = "wrapped-default",
        ---@type fun(win: number, record: notify.Record)
        ---@diagnostic disable-next-line: unused-local
        on_open = function(win, record)
            vim.api.nvim_win_set_config(win, { zindex = 999 })
        end,
        fps = 120,
        merge_duplicates = false,
    },
}
