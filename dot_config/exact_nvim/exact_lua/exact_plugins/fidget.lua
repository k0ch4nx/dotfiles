---@module "lazy"
---@type LazySpec
return {
    ---@module "fidget"
    "j-hui/fidget.nvim",
    opts = {
        -- https://github.com/j-hui/fidget.nvim?tab=readme-ov-file#options
        progress = {
            display = {
                done_ttl = 0,
                done_icon = "",
            },
        },
        notification = {
            window = {
                winblend = vim.o.winblend,
                border = "rounded",
                x_padding = 0,
            },
        },
    },
    event = "UIEnter",
}
