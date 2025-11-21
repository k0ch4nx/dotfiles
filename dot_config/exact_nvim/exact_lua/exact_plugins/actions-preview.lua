---@module "lazy"
---@type LazySpec
return {
    ---@module "actions-preview"
    "aznhe21/actions-preview.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    opts = function()
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                local telescope_builtin = require("telescope.builtin")
                vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                local opts = { buffer = ev.buf }
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, opts)
                vim.keymap.set("n", "gr", telescope_builtin.lsp_references, opts)
                vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, opts)
                vim.keymap.set("n", "<C-k>",
                    function() vim.lsp.buf.signature_help({ border = "rounded" }) end, opts)
                -- https://github.com/neovim/neovim/discussions/32045
                vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end)
                vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
                vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
                vim.keymap.set("n", "<space>wl",
                    function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, opts)
                vim.keymap.set("n", "<space>D", telescope_builtin.lsp_type_definitions, opts)
                vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
                vim.keymap.set({ "n", "v" }, "<space>ca", require("actions-preview").code_actions, opts)
                -- vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                vim.keymap.set("n", "<space>f", function() vim.lsp.buf.format({ async = true }) end, opts)
            end,
        })

        return {
            highlight_command = {
                -- https://github.com/dandavison/delta
                require("actions-preview.highlight").delta("delta --no-gitconfig --side-by-side"),
            },
            telescope = {
                results_title = false,
                layout_strategy = "vertical",
            },
        }
    end,
    event = "VeryLazy",
}
