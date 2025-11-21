---@module "lazy"
---@type LazySpec
return {
    ---@module "codeium"
    "Exafunction/windsurf.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    opts = {
        enable_chat = false,
        enable_cmp_source = false,
    },
    main  = "codeium",
    optional = true,
}
