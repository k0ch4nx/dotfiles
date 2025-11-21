---@module "lazy"
---@type LazySpec
return {
    ---@module "mason-lock"
    "zapling/mason-lock.nvim",
    dependencies = {
        "williamboman/mason.nvim",
    },
    opts = {},
    cmd = {
        "MasonLock",
        "MasonLockRestore",
    },
    event = { "VeryLazy" },
}
