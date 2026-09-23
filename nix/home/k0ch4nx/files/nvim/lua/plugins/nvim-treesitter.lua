---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-treesitter"
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "RRethy/nvim-treesitter-endwise",
    },
    opts = function()
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

        -- https://github.com/nvim-treesitter/nvim-treesitter/tree/main#adding-custom-languages
        vim.api.nvim_create_autocmd("User", {
            pattern = "TSUpdate",
            callback = function()
                require("nvim-treesitter.parsers").dotenv = {
                    install_info = {
                        url = "https://github.com/pnx/tree-sitter-dotenv",
                        revision = "a16f203ba05f8efedc780690cac217c095946c06",
                        queries = "queries",
                    },
                }
            end,
        })

        vim.treesitter.language.register("dotenv", { "env" })

        return {}
    end,
    build = ":TSUpdate",
    lazy = false,
}
