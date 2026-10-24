---@module "lazy"
---@type LazySpec
return {
    ---@module "codediff"
    "esmuellert/codediff.nvim",
    dependencies = {
        ---@module "nui"
        "MunifTanjim/nui.nvim",
    },
    cmd = "CodeDiff",
    opts = {},
}
