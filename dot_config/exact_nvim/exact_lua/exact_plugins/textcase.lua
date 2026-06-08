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
        local methods = require("strings.repeat.methods")

        vim.keymap.set({ "v" }, "<Leader>tc", function()
            local mode = vim.api.nvim_get_mode().mode

            if mode ~= "v" and mode ~= "V" then
                return
            end

            local buffer = vim.api.nvim_get_current_buf()
            local visual_region = utils.get_visual_region(
                buffer,
                true,
                nil,
                utils.get_mode_at_operator(mode)
            )

            methods.state.telescope_previous_buffer = buffer
            methods.state.telescope_previous_visual_region = visual_region
            methods.state.telescope_previous_mode = mode

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
                    picker:close()
                    main.visual(item.method_name)
                end,
                format = "text",
                preview = function(ctx)
                    ctx.preview:reset()
                    ctx.preview:minimal()

                    local text = vim.api.nvim_buf_get_text(
                        methods.state.telescope_previous_buffer or 0,
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
