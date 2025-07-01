local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    {
        ---@module "blink"
        "saghen/blink.cmp",
        dependencies = {
            "giuxtaposition/blink-cmp-copilot",
            "folke/lazydev.nvim",
        },
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = "enter",
            },
            cmdline = {
                keymap = {
                    preset = "inherit",
                },
                completion = {
                    menu = {
                        auto_show = true,
                    },
                    list = {
                        selection = {
                            preselect = false,
                            auto_insert = false,
                        },
                    },
                },
            },
            completion = {
                trigger = {
                    show_on_insert = true,
                },
                list = {
                    selection = {
                        preselect = false,
                        auto_insert = false,
                    },
                },
                accept = {
                    auto_brackets = {
                        enabled = false,
                    },
                },
                menu = {
                    winblend = vim.o.winblend,
                    -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/window.lua#L7
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                    draw = {
                        columns = {
                            { "label", "label_description", gap = 1 },
                            { "kind_icon", "kind" },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 0,
                    update_delay_ms = 50,
                    window = {
                        winblend = vim.o.winblend,
                    },
                },
                ghost_text = {
                    enabled = true,
                },
            },
            fuzzy = {
                implementation = "rust",
                prebuilt_binaries = {
                    download = false,
                },
            },
            sources = {
                default = {
                    "lsp",
                    "path",
                    "snippets",
                    "buffer",
                    "copilot",
                    "lazydev",
                },
                providers = {
                    copilot = {
                        name = "copilot",
                        module = "blink-cmp-copilot",
                        score_offset = 100,
                        async = true,
                        transform_items = function(_, items)
                            local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
                            local kind_idx = #CompletionItemKind + 1
                            CompletionItemKind[kind_idx] = "Copilot"
                            for _, item in ipairs(items) do
                                item.kind = kind_idx
                            end
                            return items
                        end,
                    },
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            signature = {
                enabled = true,
                trigger = {
                    show_on_keyword = true,
                    show_on_insert = true,
                },
                window = {
                    winblend = vim.o.winblend,
                },
            },
            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = "normal",
                kind_icons = {
                    Copilot = util.nerd_fonts.nf_oct_copilot,
                },
            },
        },
        build = "cargo build --release",
        event = { "VeryLazy" },
    },
    {
        ---@module "blink-cmp-copilot"
        "giuxtaposition/blink-cmp-copilot",
        dependencies = {
            "zbirenbaum/copilot.lua",
        },
        optional = true,
    },
}
