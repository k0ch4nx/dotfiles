---@module "lazy"
---@type LazySpec
return {
    ---@module "colorizer"
    "catgoose/nvim-colorizer.lua",
    opts = {
        filetypes = {},
        lazy_load = true,
    },
    event = "BufReadPre",
}
