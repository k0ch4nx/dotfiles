---@module "lazy"
---@type LazySpec
return {
    ---@module "textcase"
    "johmsalas/text-case.nvim",
    dependencies = {
        "folke/snacks.nvim", ---@module "snacks"
    },
    opts = {},
    config = function(self, opts)
        ---@module "textcase"
        local main = require(require("lazy.core.loader").get_main(self))
        main.setup(opts)

        local function get_visual_region(mode)
            local pos1 = vim.fn.getpos("v")
            local pos2 = vim.fn.getpos(".")
            local segments = vim.fn.getregionpos(pos1, pos2, { type = mode })
            local start = segments[1][1]
            local finish = segments[#segments][2]
            local start_row, start_col, start_off = start[2], start[3], start[4]
            local end_row, end_col, end_off = finish[2], finish[3], finish[4]

            if start_off > 0 then
                local line = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1] or ""

                if start_col <= #line then
                    start_col = vim.fn.byteidx(line, vim.fn.charidx(line, start_col - 1) + 1) + 1
                end
            end

            if end_off > 0 then
                end_col = end_col - 1
            end

            if start_col == 0 then
                local line = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1] or ""

                start_col = #line + 1
            end

            if start_row > end_row or (start_row == end_row and start_col - 1 >= end_col) then
                return
            end

            return {
                start_row = start_row,
                start_col = start_col,
                end_row = end_row,
                end_col = end_col,
            }
        end

        vim.keymap.set({ "v" }, "<Leader>tc", function()
            local mode = vim.api.nvim_get_mode().mode

            if mode ~= "v" and mode ~= "V" then
                return
            end

            local source_win = vim.api.nvim_get_current_win()
            local source_buf = vim.api.nvim_get_current_buf()

            local visual_region = get_visual_region(mode)

            if not visual_region then
                return
            end

            Snacks.picker({
                finder = function()
                    return vim
                        .iter(main.api)
                        :enumerate()
                        :map(function(i, k)
                            local api = main.api[k]

                            ---@type snacks.picker.Item
                            return {
                                idx = i - 1,
                                score = 0,
                                text = api.desc,
                                method_name = api.method_name,
                            }
                        end)
                        :totable()
                end,

                confirm = function(picker, item)
                    local method_name = item.method_name

                    picker:close()

                    vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(source_buf) then
                            return
                        end

                        if not vim.api.nvim_get_option_value("modifiable", { buf = source_buf }) then
                            return
                        end

                        local text = vim.api.nvim_buf_get_text(
                            source_buf,
                            visual_region.start_row - 1,
                            visual_region.start_col - 1,
                            visual_region.end_row - 1,
                            visual_region.end_col,
                            {}
                        )

                        local converted = main.api[method_name](table.concat(text, "\n"))

                        vim.api.nvim_buf_set_text(
                            source_buf,
                            visual_region.start_row - 1,
                            visual_region.start_col - 1,
                            visual_region.end_row - 1,
                            visual_region.end_col,
                            vim.split(converted, "\n", { plain = true })
                        )

                        if vim.api.nvim_win_is_valid(source_win) then
                            pcall(vim.api.nvim_set_current_win, source_win)
                        end
                    end)
                end,

                format = "text",

                preview = function(ctx)
                    ctx.preview:reset()
                    ctx.preview:minimal()

                    if not vim.api.nvim_buf_is_valid(source_buf) then
                        return
                    end

                    local text = vim.api.nvim_buf_get_text(
                        source_buf,
                        visual_region.start_row - 1,
                        visual_region.start_col - 1,
                        visual_region.end_row - 1,
                        visual_region.end_col,
                        {}
                    )

                    local line = main.api[ctx.item.method_name](table.concat(text, "\n"))
                    ctx.preview:set_title(ctx.item.text)
                    ctx.preview:set_lines({ line })
                end,

                layout = {
                    preset = "telescope",
                },
            })
        end)
    end,
    event = "VeryLazy",
}
