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

        local utils = require("textcase.shared.utils")

        vim.keymap.set({ "v" }, "<Leader>tc", function()
            local mode = vim.api.nvim_get_mode().mode

            if mode ~= "v" and mode ~= "V" then
                return
            end

            local source_win = vim.api.nvim_get_current_win()
            local source_buf = vim.api.nvim_get_current_buf()

            local visual_region = utils.get_visual_region(
                source_buf,
                true,
                nil,
                utils.get_mode_at_operator(mode)
            )

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
