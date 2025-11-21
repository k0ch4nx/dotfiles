---@module "lazy"
---@type LazySpec
return {
    ---@module "mason-nvim-dap"
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
        "mfussenegger/nvim-dap",
    },
    opts = function(self, opts) ---@diagnostic disable-line: unused-local
        return {
            -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
            ensure_installed = {
                "codelldb",
                "java-debug-adapter",
                "java-test",
            },
            -- https://github.com/mfussenegger/nvim-dap/discussions/869#discussioncomment-8121995
            handlers = {
                function(config) require(require("lazy.core.loader").get_main(self)).default_setup(config) end,
            },
        }
    end,
    event = { "BufNewFile", "BufReadPre", "VeryLazy" },
}
