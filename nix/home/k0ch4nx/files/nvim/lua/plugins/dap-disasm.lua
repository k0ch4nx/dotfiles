---@module "lazy"
---@type LazySpec
return {
    ---@module "dap-disasm"
    "Jorenar/nvim-dap-disasm",
    dependencies = {
        ---@module "dap-view"
        "igorlfs/nvim-dap-view",
        ---@module "dap"
        "mfussenegger/nvim-dap",
    },
    event = { "VeryLazy" },
    opts = {},
}
