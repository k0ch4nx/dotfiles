---@module "lazy"
---@type LazySpec
return {
    ---@module "dap-view"
    "igorlfs/nvim-dap-view",
    dependencies = {
        "mfussenegger/nvim-dap",
    },
    opts = {
        winbar = {
            sections = {
                "watches",
                "scopes",
                "exceptions",
                "breakpoints",
                "threads",
                "repl",
                "sessions",
                "console",
                "disassembly",
            },
            default_section = "scopes",
            controls = {
                enabled = true,
            },
        },
        virtual_text = {
            enabled = true,
        },
    },
    config = function(self, opts)
        ---@module "dap-view"
        local main = require(require("lazy.core.loader").get_main(self))
        local dap = require("dap")
        local widgets = require("dap.ui.widgets")

        main.setup(opts)

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
            vim.keymap.set("n", "<Leader>du", main.toggle, keymap_opts("DAP View: Toggle"))
            vim.keymap.set({ "n", "v" }, "<Leader>dh", main.hover, keymap_opts("DAP View: Hover"))

            vim.keymap.set({ "n", "v" }, "<Leader>dp", widgets.preview, keymap_opts("DAP: Preview"))

            vim.keymap.set("n", "<Leader>df", function()
                widgets.centered_float(widgets.frames)
            end, keymap_opts("DAP: Frames"))

            vim.keymap.set("n", "<Leader>ds", function()
                widgets.centered_float(widgets.scopes)
            end, keymap_opts("DAP: Scopes"))
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
    end,
    event = "VeryLazy",
}
