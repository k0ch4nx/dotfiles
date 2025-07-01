local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "snacks"
    "folke/snacks.nvim",
    opts = function()
        vim.iter(require("snacks.picker.config.layouts"))
            :filter(function(_, config)
                return type(config) == "table" and type(config.layout) == "table"
            end)
            :each(function(_, config)
                local function apply_highlight(nodes)
                    for _, node in ipairs(nodes) do
                        if node.box then
                            apply_highlight(node)
                        elseif vim.tbl_contains({ "input", "list" }, node.win) then
                            node.wo = vim.tbl_deep_extend("force", node.wo or {}, { winhighlight = { LineNr = "NonText" } })
                        end
                    end
                end

                apply_highlight(config.layout)
            end)

        ---@type snacks.Config
        return {
            styles = {
                input = {
                    relative = "cursor",
                    b = {
                        completion = true,
                    },
                    wo = {
                        winhighlight = {
                            LineNr = "NonText",
                        },
                    },
                },
            },
            animate = {
                fps = 120,
            },
            explorer = {
                enabled = true,
            },
            indent = {
                enabled = true,
                indent = {
                    char = util.chars.left_one_eighth_block,
                },
                animate = {
                    style = "up_down",
                },
                scope = {
                    enabled = true,
                    char = util.chars.left_one_eighth_block,
                    underline = true,
                },
            },
            input = {
                enable = true,
            },
            picker = {
                hidden = true,
                ignored = true,
                layouts = {
                    default = {
                        layout = {
                            backdrop = false,
                        },
                    },
                    explorer = {
                        preset = "sidebar",
                        layout = {
                            bo = {
                                filetype = "snacks_explorer",
                            },
                        },
                    },
                },
                sources = {
                    explorer = {
                        layout = {
                            preset = "explorer",
                        },
                    },
                    icons = {
                        layout = {
                            preset = "select",
                        },
                    },
                },
            },
        }
    end,
    keys = {
        { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
        { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
        -- { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
        { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
        { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    },
    priority = 1000,
    lazy = false,
}
