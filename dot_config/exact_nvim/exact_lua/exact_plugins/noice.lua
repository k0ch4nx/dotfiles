---@module "lazy"
---@type LazySpec
return {
    ---@module "noice"
    "folke/noice.nvim",
    dependencies = {
        "rcarriga/nvim-notify",
    },
    ---@type NoiceConfig
    opts = {
        lsp = {
            progress = {
                enabled = false,
            },
            hover = {
                enabled = false,
            },
            signature = {
                enabled = false,
            },
        },
        views = {
            cmdline_popup = {
                zindex = 1000,
            },
        },
    },
    event = "UIEnter",
}
