---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-treesitter"
    "nvim-treesitter/nvim-treesitter",
    opts = function(self)
        -- https://github.com/nvim-treesitter/nvim-treesitter/tree/main#highlighting
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "*" },
            callback = function()
                if pcall(vim.treesitter.start) then
                    -- https://github.com/nvim-treesitter/nvim-treesitter/tree/main#folds
                    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    -- https://github.com/nvim-treesitter/nvim-treesitter/tree/main#indentation
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })

        ---@type TSConfig
        return {}
    end,
    build = function(self)
        ---@module "nvim-treesitter"
        local main = require(require("lazy.core.loader").get_main(self))

        main.install("all"):wait()
        main.update():wait()
    end,
    branch = "main",
    lazy = false,
}
