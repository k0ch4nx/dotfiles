---@module "lazy"
---@type LazySpec
return {
    "vim-jp/vimdoc-ja",
    dependencies = {},
    event = "VeryLazy",
    build = "git reset --hard HEAD",
}
