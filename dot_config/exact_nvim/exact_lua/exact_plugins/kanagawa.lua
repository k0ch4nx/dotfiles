---@module "lazy"
---@type LazySpec
return {
    ---@module "kanagawa"
    "rebelot/kanagawa.nvim",
    ---@type KanagawaConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        ---@type fun(colors: KanagawaColors): table<string, table>
        overrides = function(colors)
            -- https://github.com/rebelot/kanagawa.nvim?tab=readme-ov-file#tint-background-of-diagnostic-messages-with-their-foreground-color
            local make_diagnostic_color = function(color)
                local bg = require("kanagawa.lib.color")(color):blend(colors.theme.ui.bg, 0.95):to_hex()

                return { fg = color, bg = bg }
            end

            return {
                -- https://github.com/rebelot/kanagawa.nvim?tab=readme-ov-file#transparent-floating-windows
                NormalFloat = { bg = "NONE" },
                FloatBorder = { bg = "NONE" },
                FloatTitle = { bg = "NONE" },

                DiagnosticSignHint = { link = "DiagnosticHint" },
                DiagnosticSignInfo = { link = "DiagnosticInfo" },
                DiagnosticSignWarn = { link = "DiagnosticWarn" },
                DiagnosticSignError = { link = "DiagnosticError" },

                MiniCursorword = {link = "LspReferenceText"},
                MiniCursorwordCurrent = { link = "MiniCursorword" },

                DiagnosticVirtualTextHint = make_diagnostic_color(colors.theme.diag.hint),
                DiagnosticVirtualTextInfo = make_diagnostic_color(colors.theme.diag.info),
                DiagnosticVirtualTextWarn = make_diagnostic_color(colors.theme.diag.warning),
                DiagnosticVirtualTextError = make_diagnostic_color(colors.theme.diag.error),
            }
        end,
    },
    ---@param opts KanagawaConfig
    config = function(self, opts)
        ---@module "kanagawa"
        local main = require(require("lazy.core.loader").get_main(self))

        main.setup(opts)
        main.load("wave")
    end,
    priority = math.huge,
    lazy = false,
}
