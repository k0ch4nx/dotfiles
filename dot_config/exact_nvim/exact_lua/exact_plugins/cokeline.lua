---@module "lazy"

local util = require("util")

---@type LazySpec
return {
    ---@module "cokeline"
    "willothy/nvim-cokeline",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    ---@diagnostic disable-next-line: unused-local
    opts = function(self)
        local buffers = require("cokeline.buffers")
        local hlgroups = require("cokeline.hlgroups")
        local mappings = require("cokeline.mappings")
        local state = require("cokeline.state")

        -- https://github.com/willothy/nvim-cokeline?tab=readme-ov-file#musical_keyboard-mappings
        vim.keymap.set("n", "<Tab>", function() mappings.by_step("focus", 1) end, { silent = true })
        vim.keymap.set("n", "<S-Tab>", function() mappings.by_step("focus", -1) end, { silent = true })
        vim.keymap.set("n", "<Leader>bsn", function() mappings.by_step("switch", 1) end, { silent = true })
        vim.keymap.set("n", "<Leader>bsp", function() mappings.by_step("switch", -1) end, { silent = true })
        vim.keymap.set("n", "<Leader>bpf", function() mappings.pick("focus") end, { silent = true })
        vim.keymap.set("n", "<Leader>bpc", function() mappings.pick("close") end, { silent = true })
        vim.keymap.set("n", "<Leader>bca", function() vim.iter(buffers.get_visible()):each(function(b) b:delete() end) end, { silent = true })
        vim.keymap.set("n", "<Leader>bpcm", function() mappings.pick("close-multiple") end, { silent = true })
        vim.keymap.set("n", "<Leader>bc", function() buffers.get_current():delete() end, { silent = true })

        -- https://github.com/willothy/nvim-cokeline/wiki#equally-sized-buffers

        local MIN_BUFFER_WIDTH = 24

        local get_remaining_space = function(components, buffer)
            local used_space = 0
            for _, c in pairs(components) do
                used_space = used_space + vim.fn.strwidth(
                    (type(c.text) == "string" and c.text)
                    or (type(c.text) == "function" and c.text(buffer))
                )
            end
            return math.max(0, MIN_BUFFER_WIDTH - used_space)
        end

        local components = {
            buffers = {
                lower_right_triangle = {
                    text = function(buffer)
                        return buffer.index == 1 and util.chars.space or
                            util.nerd_fonts.nf_ple_lower_right_triangle
                    end,
                    fg = hlgroups.get_hl_attr("LineNr", "bg"),
                    bg = function(buffer)
                        return buffer.index == 1 and hlgroups.get_hl_attr("LineNr", "bg") or
                            "NONE"
                    end,
                    truncation = {
                        priority = 1,
                    },
                },
                devicon = {
                    text = function(buffer) return buffer.devicon.icon end,
                    fg = function(buffer) return buffer.devicon.color end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    truncation = {
                        priority = 1,
                    },
                },
                pick_letter = {
                    text = function(buffer)
                        return (mappings.is_picking_focus() or mappings.is_picking_close()) and
                            buffer.pick_letter or util.chars.space
                    end,
                    fg = function(buffer) ---@diagnostic disable-line: unused-local
                        if mappings.is_picking_focus() then
                            return hlgroups.get_hl_attr("Identifier", "fg")
                        elseif mappings.is_picking_close() then
                            return hlgroups.get_hl_attr("PreProc", "fg")
                        end
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    truncation = {
                        priority = 1,
                    },
                },
                unique_prefix = {
                    text = function(buffer) return buffer.unique_prefix end,
                    fg = hlgroups.get_hl_attr("TabLine", "fg"),
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    italic = function(buffer) return buffer.is_modified end,
                    truncation = {
                        priority = 3,
                        direction = "left",
                    },
                },
                filename = {
                    text = function(buffer) return buffer.filename .. util.chars.space end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    underline = function(buffer) return buffer.is_hovered and not buffer.is_focused end,
                    bold = function(buffer) return buffer.is_focused end,
                    italic = function(buffer) return buffer.is_modified end,
                    truncation = {
                        priority = 2,
                        direction = "left",
                    },
                },
                read_only = {
                    text = function(buffer)
                        return buffer.is_readonly and
                            util.nerd_fonts.nf_fa_lock .. util.chars.space or util.chars.null
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    truncation = {
                        priority = 1,
                    },
                },
                close_or_unsaved = {
                    text = function(buffer)
                        local symbol

                        if buffer.is_modified then
                            symbol = util.nerd_fonts.nf_fa_circle
                        elseif buffer.is_hovered then
                            symbol = util.nerd_fonts.nf_fa_times_circle
                        else
                            symbol = util.nerd_fonts.nf_md_close_circle_outline
                        end

                        return symbol .. util.chars.space
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    on_click = function(_, _, _, _, buffer) buffer:delete() end,
                    truncation = {
                        priority = 1,
                    },
                },
                upper_left_triangle = {
                    text = util.nerd_fonts.nf_ple_upper_left_triangle,
                    fg = hlgroups.get_hl_attr("LineNr", "bg"),
                    bg = "NONE",
                    truncation = {
                        priority = 1,
                    },
                },
            },
            tabs = {
                upper_right_triangle = {
                    text = util.nerd_fonts.nf_ple_upper_right_triangle,
                    fg = hlgroups.get_hl_attr("LineNr", "bg"),
                    bg = "NONE",
                },
                lower_left_triangle = {
                    text = function(tab_page)
                        return tab_page.is_last and util.chars.null or
                            util.nerd_fonts.nf_ple_lower_left_triangle
                    end,
                    fg = hlgroups.get_hl_attr("LineNr", "bg"),
                    bg = function(tab_page)
                        return tab_page.is_last and hlgroups.get_hl_attr("LineNr", "bg") or
                            "NONE"
                    end,
                },
                close = {
                    text = function(tab_page)
                        return util.chars.space ..
                            (tab_page.is_hovered and util.nerd_fonts.nf_fa_times_circle or util.nerd_fonts.nf_md_close_circle_outline)
                    end,
                    fg = function(tab_page)
                        return hlgroups.get_hl_attr(
                            tab_page.is_active and "Normal" or "TabLine", "fg")
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    on_click = function(_, _, _, _, tab_page)
                        tab_page:close()
                        state.tab_cache = nil
                    end,
                },
                number = {
                    text = function(tab_page) return util.chars.space .. tab_page.number .. util.chars.space end,
                    fg = function(tab_page)
                        return hlgroups.get_hl_attr(
                            tab_page.is_active and "Normal" or "TabLine", "fg")
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                    bold = function(tab_page) return tab_page.is_active end,
                },
            },
            sidebar = {
                underline = {
                    text = function() return util.chars.null end,
                    bg = "NONE",
                    underline = true,
                },
            },
        }

        local padding = {
            buffers = {
                left = {
                    text = function(buffer)
                        local remaining_space = get_remaining_space(components.buffers, buffer)
                        return string.rep(util.chars.space, remaining_space / 2 + remaining_space % 2)
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                },
                right = {
                    text = function(buffer)
                        local remaining_space = get_remaining_space(components.buffers, buffer)
                        return string.rep(util.chars.space, remaining_space / 2)
                    end,
                    bg = hlgroups.get_hl_attr("LineNr", "bg"),
                },
            },
        }

        local sidebar = require("cokeline.sidebar")
        local get_components = sidebar.get_components

        sidebar.get_components = function(side)
            local sidebar_components = get_components(side)

            if #sidebar_components > 0 then
                local c = require("cokeline.components").Component.new(
                    {
                        text = function() return util.chars.box_drawings_light_vertical end,
                        highlight = "WinSeparator",
                    },
                    state.sidebar[#state.sidebar].index + 1
                )

                local winid = sidebar.get_win(side)
                local bufnr = vim.api.nvim_win_get_buf(winid)

                local buffer = buffers.Buffer.new({
                    bufnr = bufnr,
                    name = vim.fn.bufname(4),
                })

                local component = c:render(require("cokeline.context"):buffer(buffer))

                if side == "left" then
                    table.insert(sidebar_components, component)
                elseif side == "right" then
                    table.insert(sidebar_components, #sidebar_components, component)
                end
            end

            return sidebar_components
        end

        return {
            show_if_buffers_are_at_least = 0,
            buffers = {
                focus_on_delete = "prev",
                delete_on_right_click = false,
            },
            rendering = {
                max_buffer_width = MIN_BUFFER_WIDTH,
            },
            history = {
                enabled = false,
            },
            components = {
                components.buffers.lower_right_triangle,
                components.buffers.devicon,
                components.buffers.pick_letter,
                padding.buffers.left,
                components.buffers.unique_prefix,
                components.buffers.filename,
                padding.buffers.right,
                components.buffers.read_only,
                components.buffers.close_or_unsaved,
                components.buffers.upper_left_triangle,
            },
            tabs = {
                components = {
                    components.tabs.upper_right_triangle,
                    components.tabs.close,
                    components.tabs.number,
                    components.tabs.lower_left_triangle,
                },
            },
            sidebar = {
                filetype = { "snacks_explorer" },
                components = {
                    components.sidebar.underline,
                },
            },
        }
    end,
    event = { "UIEnter" },
}
