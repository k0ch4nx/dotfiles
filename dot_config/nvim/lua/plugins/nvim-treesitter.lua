---@module "lazy"
---@type LazySpec
return {
    ---@module "nvim-treesitter"
    "nvim-treesitter/nvim-treesitter",
    -- ---@return TSConfig
    -- opts = {
    --     -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
    --     ensure_installed = "all",
    --     autopairs = {
    --         enable = true,
    --     },
    --     highlight = {
    --         enable = true,
    --     },
    --     indent = {
    --         enable = true,
    --     },
    -- },
    -- main = "nvim-treesitter.configs",
    -- build = ":TSUpdate",
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
    build = ":TSUpdate",
    branch = "main",
    lazy = false,
}
