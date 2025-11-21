---@module "lazy"
---@type LazySpec
return {
    ---@module "illuminate"
    "RRethy/vim-illuminate",
    config = function()
        require("illuminate").configure({ delay = 0 })

        vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
    end,
    event = "VeryLazy",
}
