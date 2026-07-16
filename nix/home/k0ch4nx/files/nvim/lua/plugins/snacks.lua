local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "snacks"
    "folke/snacks.nvim",
    init = function()
        local group = vim.api.nvim_create_augroup("snacks_main_window", { clear = true })

        ---@param win number
        ---@return boolean
        local function is_main_candidate(win)
            if not vim.api.nvim_win_is_valid(win) then
                return false
            end

            if vim.api.nvim_win_get_config(win).relative ~= "" then
                return false
            end

            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            local bt = vim.bo[buf].buftype

            if bt ~= "" then
                return false
            end

            if ft:match("^snacks") or ft == "snacks_layout_box" then
                return false
            end

            return true
        end

        local function mark_main_windows()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                vim.w[win].snacks_main = is_main_candidate(win)
            end
        end

        vim.api.nvim_create_autocmd({
            "VimEnter",
            "WinEnter",
            "BufWinEnter",
        }, {
            group = group,
            callback = function()
                vim.schedule(mark_main_windows)
            end,
        })
    end,
    opts = function()
        ---@param item snacks.picker.Item?
        ---@return string
        local function command_history_text(item)
            if not item then
                return ""
            end

            return item.cmd or item.text or item.command or ""
        end

        ---@param cmd string
        ---@return nil
        local function open_cmdline(cmd)
            cmd = vim.trim(cmd or "")
            if cmd == "" then
                return
            end

            cmd = cmd:gsub("^:", "")

            vim.schedule(function()
                vim.api.nvim_input(":")
                vim.schedule(function()
                    vim.fn.setcmdline(cmd)
                end)
            end)
        end

        ---@param picker snacks.Picker
        ---@param fn fun()
        ---@return nil
        local function schedule_if_open(picker, fn)
            vim.schedule(function()
                if not picker.closed then
                    fn()
                end
            end)
        end

        ---@generic T : snacks.layout.Box
        ---@param layout T
        ---@return T
        local function apply_picker_winhighlight(layout)
            ---@param nodes snacks.layout.Box
            local function apply(nodes)
                for _, node in ipairs(nodes) do
                    if node.box then
                        apply(node)
                    elseif vim.tbl_contains({ "input", "list" }, node.win) then
                        node.wo = vim.tbl_deep_extend("force", node.wo or {}, {
                            winhighlight = { LineNr = "NonText" },
                        })
                    end
                end
            end

            apply(layout)
            return layout
        end

        ---@param move fun(picker: snacks.Picker)
        ---@return fun(picker: snacks.Picker)
        local function make_move_and_remember(move)
            return function(picker)
                move(picker)
                picker._cmd_history_selected_cmd = command_history_text(picker:current())
            end
        end

        ---@param picker snacks.Picker
        ---@param item snacks.picker.Item?
        ---@return boolean
        local function should_open_current(picker, item)
            local navigating_explorer = picker.opts.source == "explorer" and item and item.dir
            return not not (
                item
                and not navigating_explorer
                and #picker.list.selected > 0
                and not picker.list:is_selected(item)
            )
        end

        ---@param action string
        ---@return snacks.picker.Action
        local function open_current_if_unselected(action)
            return {
                action = function(picker, item)
                    picker:norm(function()
                        if not should_open_current(picker, item) then
                            picker:action(action)
                            return
                        end

                        local original_selected = picker.selected
                        local instance_selected = rawget(picker, "selected")
                        picker.selected = function(self, opts)
                            if opts and opts.fallback then
                                return { item }
                            end
                            return original_selected(self, opts)
                        end

                        local ok, err = xpcall(function()
                            picker:action(action)
                        end, debug.traceback)
                        rawset(picker, "selected", instance_selected)

                        if not ok then
                            error(err)
                        end
                    end)
                end,
            }
        end

        local function explorer_add(picker, item)
            local target_dir = item and Snacks.picker.util.dir(item) or picker:dir()

            Snacks.input({
                prompt = 'Add a new file or directory (directories end with a "/")',
            }, function(value)
                if not value or value:find("^%s$") then
                    return
                end

                local path = vim.fs.normalize(target_dir .. "/" .. value)
                local is_file = value:sub(-1) ~= "/"
                local dir = is_file and vim.fs.dirname(path) or path
                if is_file and vim.uv.fs_stat(path) then
                    Snacks.notify.warn("File already exists:\n- `" .. path .. "`")
                    return
                end

                vim.fn.mkdir(dir, "p")
                if is_file then
                    io.open(path, "w"):close()
                end

                local Tree = require("snacks.explorer.tree")
                Tree:open(dir)
                Tree:refresh(dir)
                require("snacks.explorer.actions").update(picker, { target = path })
            end)
        end

        vim.iter(require("snacks.picker.config.layouts"))
        ---@param config snacks.picker.layout.Config
            :filter(function(_, config)
                return type(config) == "table" and type(config.layout) == "table"
            end)
        ---@param config snacks.picker.layout.Config
            :each(function(_, config)
                apply_picker_winhighlight(config.layout)
            end)

        ---@type snacks.Config
        return {
            styles = {
                input = {
                    relative = "cursor",
                    b = {
                        completion = true,
                    },
                    wo = {
                        winhighlight = {
                            LineNr = "NonText",
                        },
                    },
                },
            },
            animate = {
                fps = 120,
            },
            explorer = {
                enabled = true,
            },
            indent = {
                enabled = true,
                indent = {
                    char = util.chars.left_one_eighth_block,
                },
                animate = {
                    style = "up_down",
                },
                scope = {
                    enabled = true,
                    char = util.chars.left_one_eighth_block,
                    underline = true,
                    priority = 0,
                },
            },
            input = {
                enabled = true,
            },
            picker = {
                hidden = true,
                ignored = true,
                layouts = {
                    default = {
                        layout = {
                            backdrop = false,
                        },
                    },
                    explorer = {
                        preset = "sidebar",
                    },
                    cmdline_history = {
                        layout = apply_picker_winhighlight({
                            backdrop = false,
                            width = 0.46,
                            height = 0.32,
                            min_width = 60,
                            min_height = 10,
                            box = "vertical",
                            border = "rounded",
                            title = "{title} {live} {flags}",
                            title_pos = "center",
                            {
                                win = "input",
                                height = 1,
                                border = "bottom",
                            },
                            {
                                win = "list",
                                border = "none",
                            },
                        }),
                    },
                },
                sources = {
                    explorer = {
                        layout = {
                            preset = "explorer",
                        },
                        win = {
                            list = {
                                keys = {
                                    ["l"] = "open_current",
                                },
                            },
                        },
                    },
                    icons = {
                        layout = {
                            preset = "select",
                        },
                    },
                    command_history = {
                        layout = {
                            preset = "cmdline_history",
                        },
                        confirm = "cmd_history_confirm_input",
                        win = {
                            input = {
                                bo = {
                                    syntax = "vim",
                                },
                                keys = {
                                    ["<Tab>"] = { "cmd_history_put_input", mode = { "i", "n" } },
                                    ["<S-Tab>"] = { "<nop>", mode = { "i", "n" } },
                                    ["<C-n>"] = { "cmd_history_input_list_down", mode = { "i", "n" } },
                                    ["<C-p>"] = { "cmd_history_input_list_up", mode = { "i", "n" } },
                                    ["/"] = { "cmd_history_focus_list", mode = "n" },
                                },
                            },
                            list = {
                                keys = {
                                    ["<Tab>"] = { "<nop>", mode = { "i", "n" } },
                                    ["<S-Tab>"] = { "<nop>", mode = { "i", "n" } },
                                    ["<CR>"] = { "cmd_history_put_input", mode = { "i", "n" } },
                                },
                            },
                        },
                    },
                },
                win = {
                    input = {
                        keys = {
                            ["<CR>"] = { "open_current", mode = { "i", "n" } },
                            ["<S-CR>"] = { { "pick_win", "jump_current" }, mode = { "i", "n" } },
                            ["<S-Tab>"] = { "select_clear", mode = { "i", "n" } },
                            ["<Tab>"] = { "select", mode = { "i", "n" } },
                            ["<C-s>"] = { "split_current", mode = { "i", "n" } },
                            ["<C-t>"] = { "tab_current", mode = { "i", "n" } },
                            ["<C-v>"] = { "vsplit_current", mode = { "i", "n" } },
                        },
                    },
                    list = {
                        keys = {
                            ["<2-LeftMouse>"] = "open_current",
                            ["<CR>"] = "open_current",
                            ["<S-CR>"] = { { "pick_win", "jump_current" } },
                            ["<S-Tab>"] = "select_clear",
                            ["<Tab>"] = { "select", mode = { "n", "x" } },
                            ["<C-s>"] = "split_current",
                            ["<C-t>"] = "tab_current",
                            ["<C-v>"] = "vsplit_current",
                        },
                    },
                },
                actions = {
                    select = {
                        action = function(picker)
                            picker.list:select()
                        end,
                    },
                    select_clear = {
                        action = function(picker)
                            picker.list:set_selected()
                        end,
                    },
                    open_current = open_current_if_unselected("confirm"),
                    jump_current = open_current_if_unselected("jump"),
                    split_current = open_current_if_unselected("edit_split"),
                    vsplit_current = open_current_if_unselected("edit_vsplit"),
                    tab_current = open_current_if_unselected("tab"),
                    explorer_add = explorer_add,
                    explorer_up = function(picker)
                        vim.fn.chdir(vim.fs.dirname(picker:cwd()))
                    end,
                    explorer_focus = function(picker)
                        vim.fn.chdir(picker:dir())
                    end,
                    cmd_history_focus_list = function(picker)
                        picker:focus("list", { show = true })
                    end,
                    cmd_history_input_list_down = make_move_and_remember(function(picker)
                        Snacks.picker.actions.list_down(picker)
                    end),
                    cmd_history_input_list_up = make_move_and_remember(function(picker)
                        Snacks.picker.actions.list_up(picker)
                    end),
                    cmd_history_put_input = function(picker)
                        local cmd = command_history_text(picker:current())
                        if cmd == "" or not picker.input then
                            return
                        end

                        picker._cmd_history_selected_cmd = nil
                        picker.input:set(cmd, "")

                        schedule_if_open(picker, function()
                            picker:focus("input", { show = true })

                            schedule_if_open(picker, function()
                                local input = picker.input
                                if input and input.win and input.win:valid() then
                                    local win = input.win.win

                                    vim.api.nvim_set_current_win(win)
                                    vim.api.nvim_win_set_cursor(win, { 1, #cmd })
                                    vim.cmd.startinsert()
                                end
                            end)
                        end)
                    end,
                    cmd_history_confirm_input = function(picker, item)
                        local cmd = picker._cmd_history_selected_cmd
                        if not cmd or cmd == "" then
                            cmd = picker.input and picker.input:get() or ""
                        end
                        if cmd == "" then
                            cmd = command_history_text(item)
                        end

                        picker._cmd_history_selected_cmd = nil
                        picker:close()
                        open_cmdline(cmd)
                    end,
                },
            },
        }
    end,
    keys = {
        { "<Leader>sp", function() Snacks.picker() end },
        { "<Leader>se", function() Snacks.explorer() end, desc = "snacks.nvim: Explorer" },
        { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
        { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
        { "grr", function() Snacks.picker.lsp_references() end, desc = "References" },
        { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
        { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
        {
            "<C-f>",
            function()
                if vim.fn.getcmdtype() ~= ":" then
                    return vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
                end

                local cmdline = vim.fn.getcmdline()
                vim.schedule(function()
                    Snacks.picker.command_history({ pattern = cmdline })
                end)

                return vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
            end,
            mode = "c",
            expr = true,
            desc = "Command History Picker",
        },
    },
    priority = 1000,
    lazy = false,
}
