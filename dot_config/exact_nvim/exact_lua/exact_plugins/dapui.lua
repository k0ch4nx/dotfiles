---@module "lazy"
---@type LazySpec
return {
    ---@module "dapui"
    "rcarriga/nvim-dap-ui",
    dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio",
    },
    ---@type dapui.config
    opts = {
        layouts = {
            {
                elements = {
                    { id = "scopes", size = 0.45 },
                    { id = "watches", size = 0.15 },
                    { id = "stacks", size = 0.25 },
                    { id = "breakpoints", size = 0.15 },
                },
                size = 40,
                position = "left",
            },
            {
                elements = {
                    { id = "console", size = 0.7 },
                    { id = "repl", size = 0.3 },
                },
                size = 10,
                position = "bottom",
            },
        },
        controls = {
            enabled = true,
            element = "repl",
        },
    },
    config = function(self, opts)
        ---@module "dapui"
        local main = require(require("lazy.core.loader").get_main(self))

        local dap = require("dap")
        local widgets = require("dap.ui.widgets")

        main.setup(opts)

        local layout_state = {
            active = false,
            explorer_was_open = false,
            restored = true,
        }

        local dapui_filetypes = {
            dapui_scopes = true,
            dapui_watches = true,
            dapui_stacks = true,
            dapui_breakpoints = true,
            dapui_console = true,
            ["dap-repl"] = true,
        }

        local function get_snacks()
            return rawget(_G, "Snacks")
        end

        local function open_explorer()
            local snacks = get_snacks()
            if not snacks or not snacks.explorer then
                return
            end

            if snacks.explorer.open then
                snacks.explorer.open()
            else
                snacks.explorer()
            end
        end

        local function is_dapui_open()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.bo[buf].filetype
                local is_normal_win = vim.api.nvim_win_get_config(win).relative == ""

                if is_normal_win and dapui_filetypes[ft] then
                    return true
                end
            end

            return false
        end

        local function close_explorer_and_save_state()
            layout_state.explorer_was_open = false

            local snacks = get_snacks()
            if not snacks or not snacks.picker then
                return
            end

            local explorers = snacks.picker.get({ source = "explorer" }) or {}

            if #explorers > 0 then
                layout_state.explorer_was_open = true
            end

            for _, picker in ipairs(explorers) do
                picker:close()
            end
        end

        local function open_explorer_if_needed()
            if not layout_state.explorer_was_open then
                return
            end

            open_explorer()
        end

        local function open_debug_ui()
            if not layout_state.active then
                layout_state.active = true
                layout_state.restored = false

                close_explorer_and_save_state()
            end

            vim.schedule(function()
                main.open()
            end)
        end

        local function close_debug_ui()
            main.close()
        end

        local function restore_debug_ui(force_open_explorer)
            main.close()

            local should_open_explorer = force_open_explorer or layout_state.explorer_was_open
            if layout_state.restored and not should_open_explorer then
                return
            end

            layout_state.restored = true
            layout_state.active = false

            vim.schedule(function()
                if force_open_explorer then
                    open_explorer()
                else
                    open_explorer_if_needed()
                end

                layout_state.explorer_was_open = false
            end)
        end

        local function toggle_debug_ui()
            if is_dapui_open() then
                restore_debug_ui()
            else
                open_debug_ui()
            end
        end

        local function toggle_explorer()
            if is_dapui_open() then
                restore_debug_ui(true)
                return
            end

            local snacks = get_snacks()
            if snacks and snacks.explorer then
                snacks.explorer()
            end
        end

        main.toggle_explorer = toggle_explorer

        local function has_dap_config(bufnr)
            local ft = vim.bo[bufnr].filetype
            local configs = dap.configurations[ft]

            return configs ~= nil
        end

        local function set_dap_keymaps(bufnr)
            if vim.b[bufnr].dap_keymaps_set then
                return
            end

            if not has_dap_config(bufnr) then
                return
            end

            vim.b[bufnr].dap_keymaps_set = true

            local function keymap_opts(desc)
                return {
                    buffer = bufnr,
                    silent = true,
                    desc = desc,
                }
            end

            vim.keymap.set("n", "<F5>", dap.continue, keymap_opts("DAP: Continue"))
            vim.keymap.set("n", "<F10>", dap.step_over, keymap_opts("DAP: Step Over"))
            vim.keymap.set("n", "<F11>", dap.step_into, keymap_opts("DAP: Step Into"))
            vim.keymap.set("n", "<S-F11>", dap.step_out, keymap_opts("DAP: Step Out"))
            vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, keymap_opts("DAP: Toggle Breakpoint"))
            vim.keymap.set("n", "<C-S-F5>", dap.stop, keymap_opts("DAP: Stop"))
            vim.keymap.set("n", "<C-S-F5>", dap.restart, keymap_opts("DAP: Restart"))

            vim.keymap.set("n", "<Leader>dl", function()
                dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
            end, keymap_opts("DAP: Log Point"))

            vim.keymap.set("n", "<Leader>dr", dap.repl.open, keymap_opts("DAP: Open REPL"))

            vim.keymap.set("n", "<Leader>du", toggle_debug_ui, keymap_opts("DAP UI: Toggle"))

            vim.keymap.set({ "n", "v" }, "<Leader>dh", widgets.hover, keymap_opts("DAP UI: Hover"))
            vim.keymap.set({ "n", "v" }, "<Leader>dp", widgets.preview, keymap_opts("DAP UI: Preview"))

            vim.keymap.set("n", "<Leader>df", function()
                widgets.centered_float(widgets.frames)
            end, keymap_opts("DAP UI: Frames"))

            vim.keymap.set("n", "<Leader>ds", function()
                widgets.centered_float(widgets.scopes)
            end, keymap_opts("DAP UI: Scopes"))
        end

        local group = vim.api.nvim_create_augroup("dap-buffer-keymaps", {
            clear = true,
        })

        vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "LspAttach" }, {
            group = group,
            callback = function(args)
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(args.buf) then
                        set_dap_keymaps(args.buf)
                    end
                end)
            end,
        })

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) then
                set_dap_keymaps(bufnr)
            end
        end

        dap.listeners.before.launch.dapui_config = open_debug_ui
        dap.listeners.before.attach.dapui_config = open_debug_ui

        dap.listeners.after.event_stopped.dapui_config = open_debug_ui

        dap.listeners.after.event_terminated.dapui_config = restore_debug_ui
        dap.listeners.after.event_exited.dapui_config = restore_debug_ui

        dap.listeners.before.terminate.dapui_config = close_debug_ui
        dap.listeners.before.disconnect.dapui_config = close_debug_ui
    end,
    event = "VeryLazy",
}
