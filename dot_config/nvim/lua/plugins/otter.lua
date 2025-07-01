---@module "lazy"
---@type LazySpec
return {
    ---@module "otter"
    "jmbuhr/otter.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
        vim.api.nvim_create_user_command("OtterActivate", function() require("otter").activate() end, {})
        ---@type OtterConfig
        return {
            lsp = {
                diagnostic_update_events = { "BufWritePost", "InsertLeave", "TextChanged" },
            },
        }
    end,
    lazy = false,
}
