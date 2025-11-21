local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "textcase"
    "johmsalas/text-case.nvim",
    dependencies = {
        "folke/snacks.nvim",
    },
    opts = {},
    config = function(self, opts)
        ---@module "textcase"
        local main = require(require("lazy.core.loader").get_main(self))
        main.setup(opts)

        vim.keymap.set({ "v" }, "<leader>tc", function()
            local mode = vim.api.nvim_get_mode().mode

            if mode ~= "v" then
                return
            end

            local selection = util.fn.get_visual_selection()

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

                    local line = main.api[ctx.item.method_name](selection)
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
