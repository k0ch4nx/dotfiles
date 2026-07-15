---@module "lazy"
---@type LazySpec
return {
    ---@module "dap-disasm"
    "Jorenar/nvim-dap-disasm",
    dependencies = {
        "igorlfs/nvim-dap-view",
        "mfussenegger/nvim-dap",
    },
    opts = {},
    event = "VeryLazy",
}
