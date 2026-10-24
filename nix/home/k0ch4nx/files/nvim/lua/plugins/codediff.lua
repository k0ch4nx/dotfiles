---@module "lazy"
---@type LazySpec
return {
    ---@module "codediff"
    "esmuellert/codediff.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    cmd = "CodeDiff",
    opts = {},
}
