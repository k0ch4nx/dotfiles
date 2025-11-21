---@module "lazy"

local util = require("util")

---@type LazySpec
return {
    {
        ---@module "telescope"
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-telescope/telescope-fzf-native.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "tiagovla/scope.nvim",

            "nvim-lua/plenary.nvim",
        },
        opts = function()
            local actions = require("telescope.actions")
            local config = require("telescope.config")

            local vimgrep_arguments = { unpack(config.values.vimgrep_arguments) }
            table.insert(vimgrep_arguments, "--text")

            return {
                defaults = {
                    winblend = vim.o.winblend,
                    mappings = {
                        n = {
                            ["q"] = actions.close,
                        },
                    },
                    vimgrep_arguments = vimgrep_arguments,
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        follow = true,
                    },
                    live_grep = {
                        hidden = true,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
            }
        end,
        config = function(self, opts)
            ---@module "telescope"
            local main = require(require("lazy.core.loader").get_main(self))

            main.setup(opts)

            main.load_extension("fzf")
            main.load_extension("scope")
            main.load_extension("ui-select")
        end,
        event = "VeryLazy",
    },
    {
        ---@module "fzf_lib"
        "nvim-telescope/telescope-fzf-native.nvim",
        build = {
            "cmake -S . -B build -D CMAKE_BUILD_TYPE=Release -D CMAKE_POLICY_VERSION_MINIMUM=3.5 --fresh",
            "cmake --build build --config Release --clean-first",
            util.conditions.is_windows and "cmake --install build --prefix build" or nil,
        },
        optional = true,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        optional = true,
    },
}
