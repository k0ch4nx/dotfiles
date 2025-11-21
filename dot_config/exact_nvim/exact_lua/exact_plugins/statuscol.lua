---@module "lazy"
---@type LazySpec
return {
    ---@module "statuscol"
    "luukvbaal/statuscol.nvim",
    opts = function(self, opts) ---@diagnostic disable-line: unused-local
        local builtin = require("statuscol.builtin")

        local ft_ignore = { "neo-tree" }

        -- https://github.com/kevinhwang91/nvim-ufo/issues/33#issuecomment-2139228079
        vim.api.nvim_create_autocmd("FileType", {
            pattern = ft_ignore,
            callback = function()
                require("ufo").detach()
                -- vim.opt_local.foldenable = false
                -- vim.opt_local.foldcolumn = "0"
            end,
        })

        return {
            segments = {
                -- https://github.com/luukvbaal/statuscol.nvim/blob/main/lua/statuscol.lua#L416-L418
                { sign = { namespace = { "gitsigns" }, auto = true }, click = "v:lua.ScSa" },
                { sign = { namespace = { "diagnostic" }, auto = true }, click = "v:lua.ScSa" },
                { sign = { name = { "Dap" }, maxwidth = 1, auto = true }, click = "v:lua.ScSa" },
                { text = { builtin.lnumfunc, " " }, condition = { true, builtin.not_empty }, click = "v:lua.ScLa" },
                { text = { builtin.foldfunc, "" }, condition = { true, builtin.not_empty }, click = "v:lua.ScFa" },
            },
        }
    end,
    event = "UIEnter",
}
