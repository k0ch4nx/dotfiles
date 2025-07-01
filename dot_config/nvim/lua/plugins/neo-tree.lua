---@module "lazy"
---@type LazySpec
return {
    ---@module "neo-tree"
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
        "folk/snacks.nvim",

        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    ---@type neotree.Config?
    opts = {
        sources = { "filesystem" },
        close_if_last_window = true,
        enable_cursor_hijack = true,
        open_files_do_not_replace_types = { "terminal" },
        popup_border_style = "rounded",
        default_component_configs = {
            diagnostics = {
                highlights = {
                    hint = "DiagnosticHint",
                    info = "DiagnosticInfo",
                    warn = "DiagnosticWarn",
                    error = "DiagnosticError",
                },
            },
            symlink_target = {
                enabled = true,
            },
        },
        window = {
            mappings = {
                ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = true } },
            },
        },
        filesystem = {
            -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/1452
            scan_mode = "deep",
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
            },
            follow_current_file = {
                enabled = true,
            },
            use_libuv_file_watcher = true,
        },
        event_handlers = {
            {
                event = "neo_tree_popup_input_ready",
                handler = function(args)
                    vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, { noremap = true, buffer = args.bufnr })
                end,
            },
            {
                event = "neo_tree_window_after_open",
                handler = function(args)
                    if args.position == "left" or args.position == "right" then
                        vim.cmd("wincmd =")
                    end
                end,
            },
            {
                event = "neo_tree_window_after_close",
                handler = function(args)
                    if args.position == "left" or args.position == "right" then
                        vim.cmd("wincmd =")
                    end
                end,
            },
            {
                event = "file_moved",
                handler = function(args)
                    Snacks.rename.on_rename_file(args.source, args.destination)
                end,
            },
            {
                event = "file_renamed",
                handler = function(args)
                    Snacks.rename.on_rename_file(args.source, args.destination)
                end,
            },
        },
    },
    lazy = false,
}
