---@module "lazy"
---@type LazySpec
return {
    "vim-jp/vimdoc-ja",
    dependencies = {},
    build = "git reset --hard HEAD",
    event = "VeryLazy",
}
