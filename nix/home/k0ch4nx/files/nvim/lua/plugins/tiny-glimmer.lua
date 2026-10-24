---@module "lazy"
---@type LazySpec
return {
    ---@module "tiny-glimmer"
    "rachartier/tiny-glimmer.nvim",
    event = { "VeryLazy" },
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
}
