---@module "lazy"
---@type LazySpec
return {
    ---@module "neominimap"
    "Isrothy/neominimap.nvim",
    init = function()
        vim.opt.wrap = false
        vim.opt.sidescrolloff = 36

        ---@type Neominimap.UserConfig
        vim.g.neominimap = {
            auto_enable = true,
            layout = "float",
        }
    end,
    lazy = false,
}
