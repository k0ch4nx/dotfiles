-- https://neovim.io/doc/user/quickref.html

pcall(require, "config.options")
pcall(require, "config.autocmds")
pcall(require, "config.keymaps")

if not vim.g.vscode then
    pcall(require, "config.lazy")
end
