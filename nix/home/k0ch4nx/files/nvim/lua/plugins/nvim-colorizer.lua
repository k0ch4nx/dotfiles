---@module "lazy"
---@type LazySpec
return {
    ---@module "colorizer"
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre" },
    opts = {
        filetypes = {},
        lazy_load = true,
    },
}
