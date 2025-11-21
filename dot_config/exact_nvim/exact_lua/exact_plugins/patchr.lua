---@module "lazy"
---@type LazySpec
return {
    ---@module "patchr"
    "nhu/patchr.nvim",
    opts = function(self, opts)
        local cmd = require("patchr.cmd")
        local config = require("patchr.config")

        local group = vim.api.nvim_create_augroup("patchr", { clear = false })
        local locked = false

        local function guard(fn)
            return function(...)
                if not locked then return fn(...) end
            end
        end

        local reset = function()
            vim.iter(config.get_plugin_names()):each(function(p)
                cmd.reset({ p })
            end)
        end

        local apply = function()
            vim.iter(config.get_plugin_names()):each(function(p)
                cmd.apply({ p }, true)
            end)
        end

        local function register(pattern)
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = pattern .. "Pre",
                callback = guard(reset),
            })

            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = pattern,
                callback = guard(apply),
            })
        end

        vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "LazySyncPre",
            callback = function()
                locked = true
                reset()
            end,
        })

        vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "LazySync",
            callback = function()
                apply()
                locked = false
            end,
        })

        vim.iter({ "LazyInstall", "LazyUpdate", "LazyCheck" }):each(register)

        ---@type patchr.config
        return {
            autocmds = false,
            plugins = {
                ["mason-null-ls.nvim"] = {
                    vim.fs.joinpath(vim.fn.stdpath("config"), "patches", "mason-null-ls.patch"),
                },
                ["mason-nvim-dap.nvim"] = {
                    vim.fs.joinpath(vim.fn.stdpath("config"), "patches", "mason-nvim-dap.patch"),
                },
                ["snacks.nvim"] = {
                    vim.fs.joinpath(vim.fn.stdpath("config"), "patches", "snacks.patch"),
                },
                ["which-key.nvim"] = {
                    vim.fs.joinpath(vim.fn.stdpath("config"), "patches", "which-key.patch"),
                },
            },
        }
    end,
    lazy = false,
}
