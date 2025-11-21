---@module "lazy"
---@type LazySpec
return {
    ---@module "scope"
    "tiagovla/scope.nvim",
    -- https://github.com/tiagovla/scope.nvim/blob/main/lua/scope/config.lua
    opts = {},
    -- https://github.com/tiagovla/.dotfiles/blob/master/neovim/.config/nvim/lua/plugins/modules.lua#L11
    event = { "BufRead" },
}
