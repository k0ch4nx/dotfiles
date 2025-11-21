local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "lualine"
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvimtools/none-ls.nvim",
        "rebelot/kanagawa.nvim",

        "nvim-tree/nvim-web-devicons",
    },
    opts = function()
        -- https://github.com/nvim-lualine/lualine.nvim/blob/master/examples/slanted-gaps.lua

        local empty = require("lualine.component"):extend()
        local colors = require("kanagawa.colors").setup()

        function empty:draw(default_highlight)
            self.status = ""
            self.applied_separator = ""
            self:apply_highlights(default_highlight)
            self:apply_section_separators()
            return self.status
        end

        local function process_sections(sections)
            for name, section in pairs(sections) do
                local left = name:sub(9, 10) < "x"
                for pos = 1, name ~= "lualine_z" and #section or #section - 1 do
                    table.insert(section, pos * 2,
                        { empty, color = { fg = colors.theme.syn.punct, bg = colors.theme.syn.punct } })
                end
                for id, comp in ipairs(section) do
                    if type(comp) ~= "table" then
                        comp = { comp }
                        section[id] = comp
                    end
                    comp.separator = left and { right = util.nerd_fonts.nf_ple_lower_left_triangle } or
                        { left = util.nerd_fonts.nf_ple_lower_right_triangle }
                end
            end
            return sections
        end

        local lsp = function()
            local clients = vim.iter(vim.lsp.get_clients({ bufnr = 0 }))
                :map(function(client)
                    local name = client.id .. ":" .. client.name
                    if client.name == "null-ls" then
                        return (name .. "[%s]"):format(table.concat(
                            vim.iter(require("null-ls.sources").get_available(vim.bo.filetype))
                            :map(function(source)
                                return source.name
                            end)
                            :totable(),
                            " "
                        ))
                    else
                        return name
                    end
                end)
                :totable()
            if not next(clients) then
                return "󰚦"
            else
                return "󱐋" .. " " .. table.concat(clients, " ")
            end
        end

        return {
            options = {
                component_separators = util.chars.null,
                section_separators = { left = util.nerd_fonts.nf_ple_lower_left_triangle, right = util.nerd_fonts.nf_ple_lower_right_triangle },
                globalstatus = true,
            },
            sections = process_sections({
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    {
                        "filename",
                        path = 1,
                        shorting_target = 0,
                    },
                },
                lualine_x = {
                    {
                        lsp,
                    },
                    "encoding",
                    { -- https://github.com/nvim-lualine/lualine.nvim/wiki/Component-snippets#display-eol-fileformat-as-crlf
                        "fileformat",
                        icons_enabled = true,
                        symbols = {
                            unix = "LF",
                            dos = "CRLF",
                            mac = "CR",
                        },
                    },
                    "filetype",
                },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            }),
        }
    end,
    event = { "UIEnter" },
}
