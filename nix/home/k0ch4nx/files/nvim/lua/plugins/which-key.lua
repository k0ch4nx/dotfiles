local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "which-key"
    "folke/which-key.nvim",
    ---@type wk.Opts
    opts = {
        win = {
            no_overlap = false,
            border = util.opt.winborder,
        },
    },
    event = "VeryLazy",
}
