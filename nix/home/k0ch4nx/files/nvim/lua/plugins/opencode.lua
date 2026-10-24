---@module "lazy"
---@type LazySpec
return {
    ---@module "opencode"
    "nickjvandyke/opencode.nvim",
    event = { "VeryLazy" },
    keys = {
        {
            "<Leader>oa",
            function()
                require("opencode").ask("@this: ")
            end,
            mode = { "n", "x" },
            desc = "Ask OpenCode",
        },
    },
    init = function()
        vim.g.opencode_opts = {
            server = {
                start = function()
                    vim.cmd("vsplit term://opencode2 | wincmd p")
                end,
            },
        }
    end,
}
