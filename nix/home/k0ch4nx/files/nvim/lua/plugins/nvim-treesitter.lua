---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-treesitter"
    "neovim-treesitter/nvim-treesitter",
    dependencies = {
        "neovim-treesitter/treesitter-parser-registry",
        "RRethy/nvim-treesitter-endwise",
    },
    opts = function()
        -- https://github.com/neovim-treesitter/nvim-treesitter/tree/main#highlighting
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "*" },
            callback = function()
                if pcall(vim.treesitter.start) then
                    -- https://github.com/neovim-treesitter/nvim-treesitter/tree/main#folds
                    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    -- https://github.com/neovim-treesitter/nvim-treesitter/tree/main#indentation
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })

        ---@type TSConfig
        return {
            local_parsers = {
                dotenv = {
                    source = {
                        type = "self_contained",
                        url = "https://github.com/pnx/tree-sitter-dotenv",
                        queries_path = "queries",
                        semver = false,
                    },
                    parser_manifest = {
                        parser_version = "main",
                    },
                    filetypes = { "dotenv", "sh" },
                },
            },
        }
    end,
    build = ":TSUpdate",
    lazy = false,
}
