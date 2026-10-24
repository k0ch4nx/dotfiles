---@module "lazy"
---@type LazySpec
return {
    ---@module "crates"
    "saecki/crates.nvim",
    event = "VeryLazy",
    opts = {
        popup = {
            border = "rounded",
        },
        lsp = {
            enabled = true,
            actions = true,
            completion = true,
            hover = true,
        },
    },
}
