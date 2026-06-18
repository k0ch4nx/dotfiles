local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "snacks"
    "folke/snacks.nvim",
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
                enable = true,
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
                            ["<S-Tab>"] = { "<nop>", mode = { "i", "n" } },
                            ["<Tab>"] = { "select", mode = { "i", "n" } },
                        },
                    },
                    list = {
                        keys = {
                            ["<S-Tab>"] = { "<nop>", mode = { "i", "n" } },
                            ["<Tab>"] = { "select", mode = { "i", "n" } },
                        },
                    },
                },
                actions = {
                    select = function(self)
                        self.list:select()
                    end,
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
        {
            "<Leader>se",
            function()
                local dapui = package.loaded.dapui

                if dapui and dapui.toggle_explorer then
                    dapui.toggle_explorer()
                    return
                end

                Snacks.explorer()
            end,
            desc = "snacks.nvim: Explorer",
        },
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
