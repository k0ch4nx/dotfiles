local util = require("util")

-- Prepend mise shims to PATH
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.editorconfig = false

-- https://github.com/neovim/neovim/issues/20107
vim.o.complete = ""
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.fileformat = "unix"
vim.o.fileformats = "unix,dos,mac"
vim.o.fillchars = "fold: ,foldopen:󰅀,foldclose:󰅂,foldsep: ,eob: "
vim.o.foldcolumn = "auto"
vim.o.foldlevelstart = 99
vim.o.hidden = true
vim.o.laststatus = 3
vim.o.list = true
vim.o.listchars = "tab: ,space:·,extends:›,precedes:‹,nbsp:␣"
vim.o.more = false
vim.o.mouse = "a"
vim.o.mousemoveevent = true
vim.o.number = true
vim.o.pumblend = 10
vim.o.relativenumber = true
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.splitkeep = "screen"
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.termguicolors = true
vim.o.timeoutlen = 300
vim.o.updatetime = 50
vim.o.winblend = 10
vim.o.wildchar = 0
vim.o.winborder = "rounded"

if util.conditions.is_windows then
    -- https://neovim.io/doc/user/options.html#shell-powershell
    -- https://github.com/akinsho/toggleterm.nvim/wiki/Tips-and-Tricks#using-toggleterm-with-powershell
    vim.o.shell = vim.fn.executable("pwsh") == 1 and "pwsh \"-NoLogo\"" or "powershell \"-NoLogo\""
    vim.o.shellcmdflag = "-NoProfile -ExecutionPolicy Bypass -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    vim.o.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
    vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""

    vim.g.python3_host_prog = "$PYENV\\shims\\python.bat"
end

vim.filetype.add({
    extension = {
        ["tmpl"] = "gotmpl",
    },
    filename = {
        ["Brewfile"] = "ruby",
        [".Brewfile"] = "ruby",

        ["docker-compose.yaml"] = "yaml.docker-compose",
        ["docker-compose.yml"] = "yaml.docker-compose",
        ["compose.yaml"] = "yaml.docker-compose",
        ["compose.yml"] = "yaml.docker-compose",

        [".chezmoiignore"] = "gotmpl",
        [".chezmoiremove"] = "gotmpl",
    },
})

vim.diagnostic.config({
    virtual_text = {
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = util.nerd_fonts.nf_cod_error,
            [vim.diagnostic.severity.WARN] = util.nerd_fonts.nf_cod_warning,
            [vim.diagnostic.severity.INFO] = util.nerd_fonts.nf_cod_info,
            [vim.diagnostic.severity.HINT] = util.nerd_fonts.nf_md_lightbulb_outline,
        },
    },
    float = {
        source = true,
        border = "rounded",
    },
    update_in_insert = true,
    severity_sort = true,
})

vim.lsp.config("*", {
    ---@type vim.lsp.client.on_attach_cb
    on_attach = function(client, bufnr)
        if vim.bo[bufnr].buftype == "terminal" then
            client:stop(true)
            return
        end

        if client:supports_method("textDocument/inlayHint", bufnr) or client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})
