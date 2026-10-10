local util = require("util")

---@type vim.lsp.Config
return {
    settings = {
        -- https://luals.github.io/wiki/settings
        Lua = {
            codeLens = {
                enable = true,
            },
            format = {
                -- https://github.com/CppCXY/EmmyLuaCodeStyle/blob/master/CodeFormatCore/src/Config/LuaStyle.cpp
                defaultConfig = {
                    quote_style = "double",
                    trailing_table_separator = "smart",
                    max_line_length = "unset",
                    align_continuous_assign_statement = "false",
                    align_continuous_rect_table_field = "false",
                    align_array_table = "false",
                },
            },
            hint = {
                enable = true,
                arrayIndex = "Enable",
            },
            hover = {
                previewFields = util.math.i32_max,
            },
            workspace = {
                maxPreload = util.math.i32_max,
                -- https://github.com/LuaLS/lua-language-server/issues/2399
                preloadFileSize = 1024 * 1024 * 10,
            },
        },
    },
}
