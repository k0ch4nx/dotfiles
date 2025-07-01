load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- https://lazy.folke.io/configuration
-- https://lazy.folke.io/spec
-- https://neovim.io/doc/user/autocmd.html#autocmd-events https://neovim.io/doc/user/deprecated.html
require("lazy").setup(
    { { import = "plugins" } },
    {
        defaults = {
            lazy = true,
            ---@param self LazyPlugin
            cond = function(self)
                local disabled_plugins = {
                    "CopilotChat.nvim",
                    "actions-preview.nvim",
                    "hardtime.nvim",
                    "neo-tree.nvim",
                    "patchr.nvim",
                    "telescope.nvim",
                    "vim-illuminate",
                }

                return not vim.tbl_contains(disabled_plugins, self.name)
            end,
        },
        concurrency = math.huge,
        git = {
            timeout = math.huge,
        },
        ui = {
            border = "rounded",
            backdrop = 100,
        },
        rocks = {
            enabled = false,
        },
        performance = {
            rtp = {
                disabled_plugins = {
                    -- "gzip",
                    -- "matchit",
                    -- "matchparen",
                    "netrwPlugin",
                    -- "tarPlugin",
                    "tohtml",
                    "tutor",
                    -- "zipPlugin",
                },
            },
        },
    }
)
