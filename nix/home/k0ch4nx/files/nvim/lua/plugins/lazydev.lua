---@module "lazy"
---@type LazySpec
return {
    {
        "Bilal2453/luvit-meta",
        optional = true,
    },
    {
        "sudo-tee/wezterm-types",
        optional = true,
    },
    {
        ---@module "lazydev"
        "folke/lazydev.nvim",
        dependencies = {
            "Bilal2453/luvit-meta",
            "DrKJeff16/wezterm-types",
        },
        ---@type lazydev.Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            library = {
                { path = "luvit-meta/library", words = { "vim%.uv" } },
                { path = "wezterm-types", mods = { "wezterm" } },
            },
        },
        ft = "lua",
    },
}
