---@module "lazy"
---@type LazySpec
return {
    ---@module "tiny-glimmer"
    "rachartier/tiny-glimmer.nvim",
    opts = {
        overwrite = {
            undo = {
                enabled = true,
            },
            redo = {
                enabled = true,
            },
        },
        hijack_ft_disabled = {
            "snacks_picker_input",
            "snacks_picker_list",
        },
    },
    event = "VeryLazy",
}
