-- https://neovim.io/doc/user/quickref.html

require("config.options")
require("config.autocmds")
require("config.keymaps")

if not vim.g.vscode then
    require("config.lazy")
end
