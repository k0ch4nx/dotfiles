---@module "lazy"

local util = require("util")

---@type LazySpec
return {
    { ---@module "copilot"
        "zbirenbaum/copilot.lua",
        ---@type CopilotConfig
        opts = {
            -- https://github.com/zbirenbaum/copilot.lua/discussions/424#discussioncomment-12717404
            server_opts_overrides = {
                settings = {
                    telemetry = {
                        telemetryLevel = "off",
                    },
                },
            },
            panel = { enabled = false },
            suggestion = { enabled = false },
        },
        event = "VeryLazy",
    },
    {
        ---@module "CopilotChat"
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            "zbirenbaum/copilot.lua",

            "nvim-lua/plenary.nvim",
        },
        ---@type CopilotChat.config?
        opts = {
            model = "gemini-2.5-pro",
            window = {
                layout = "float",
                relative = "cursor",
                width = 1,
                height = 0.4,
                row = 1,
                border = "rounded",
            },
            show_folds = false,
            mappings = {
                show_diff = {
                    full_diff = true,
                },
            },
        },
        build = (util.conditions.is_linux or util.conditions.is_mac) and "make tiktoken" or nil,
        event = "VeryLazy",
    },
}
