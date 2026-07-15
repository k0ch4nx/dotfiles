---@module "lazy"
---@type LazySpec
return {
    "aznhe21/actions-preview.nvim",
    ---@module "actions-preview"
    dependencies = {
        ---@module "snacks"
        "folke/snacks.nvim",
    },
    opts = function()
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                local opts = { buffer = ev.buf }
                vim.keymap.set({ "n", "v" }, "gra", require("actions-preview").code_actions, opts)
            end,
        })

        return {
            highlight_command = {
                -- https://github.com/dandavison/delta
                require("actions-preview.highlight").delta("delta --no-gitconfig --side-by-side"),
            },
            backend = { "snacks" },
            ---@type snacks.picker.Config
            snacks = {
                layout = { preset = "default" },
            },
        }
    end,
    event = "VeryLazy",
}
