---@module "lazy"
---@type LazySpec
return {
    ---@module "gitsigns"
    "lewis6991/gitsigns.nvim",
    ---@return Gitsigns.Config
    opts = function(self)
        return {
            numhl = true,
            linehl = true,
            current_line_blame = true,
            current_line_blame_opts = {
                delay = 0,
            },
            preview_config = {
                border = "rounded",
            },
            on_attach = function(bufnr)
                -- https://github.com/lewis6991/gitsigns.nvim?tab=readme-ov-file#keymaps

                ---@module "gitsigns"
                local gitsigns = require(require("lazy.core.loader").get_main(self))

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end)

                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end)

                -- Actions
                map("n", "<leader>hs", gitsigns.stage_hunk)
                map("n", "<leader>hr", gitsigns.reset_hunk)

                map("v", "<leader>hs", function()
                    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end)

                map("v", "<leader>hr", function()
                    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end)

                map("n", "<leader>hS", gitsigns.stage_buffer)
                map("n", "<leader>hR", gitsigns.reset_buffer)
                map("n", "<leader>hp", gitsigns.preview_hunk)
                map("n", "<leader>hi", gitsigns.preview_hunk_inline)

                map("n", "<leader>hb", function()
                    gitsigns.blame_line({ full = true })
                end)

                map("n", "<leader>hd", gitsigns.diffthis)

                map("n", "<leader>hD", function()
                    gitsigns.diffthis("~")
                end)

                map("n", "<leader>hQ", function() gitsigns.setqflist("all") end)
                map("n", "<leader>hq", gitsigns.setqflist)

                -- Toggles
                map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
                map("n", "<leader>td", gitsigns.toggle_deleted)
                map("n", "<leader>tw", gitsigns.toggle_word_diff)

                -- Text object
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
            end,
        }
    end,
    event = "VeryLazy",
}
