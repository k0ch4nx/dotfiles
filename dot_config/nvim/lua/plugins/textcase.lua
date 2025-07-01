---@module "lazy"
---@type LazySpec
return {
    "johmsalas/text-case.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    opts = {},
    config = function(self, opts)
        ---@module "textcase"
        local main = require(require("lazy.core.loader").get_main(self))
        main.setup(opts)

        -- require("telescope").load_extension("textcase")
    end,
    event = "VeryLazy",
}
