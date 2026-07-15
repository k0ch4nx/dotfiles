---@module "lazy"
---@type LazySpec
return {
    ---@module "mason-lock"
    "zapling/mason-lock.nvim",
    dependencies = {
        "williamboman/mason.nvim",
    },
    opts = {
        lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json",
    },
    cmd = {
        "MasonLock",
        "MasonLockRestore",
    },
    event = { "VeryLazy" },
}
