---@module "lazy"
---@type LazySpec
return {
    "terryma/vim-expand-region",
    init = function()
        vim.g.expand_region_text_objects = {
            iw = 0,
            iW = 0,
            ["i\""] = 1,
            ["i'"] = 1,
            ia = 0,
            ["i]"] = 1,
            ib = 1,
            iB = 1,
            il = 0,
            im = 1,
            am = 1,
            ie = 0,
        }
    end,
    lazy = false,
}
