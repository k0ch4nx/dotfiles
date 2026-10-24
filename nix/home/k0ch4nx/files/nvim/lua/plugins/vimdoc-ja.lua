---@module "lazy"
---@type LazySpec
return {
    ---@module "vimdoc-ja"
    "vim-jp/vimdoc-ja",
    dependencies = {},
    event = { "VeryLazy" },
    build = "git reset --hard HEAD",
}
