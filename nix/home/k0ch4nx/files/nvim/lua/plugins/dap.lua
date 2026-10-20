---@module "lazy"
---@type LazySpec
return {
    ---@module "dap"
    "mfussenegger/nvim-dap",
    init = function()
        vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
        vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
    end,
    config = function()
        local dap = require("dap")
        local nix = require("util").nix_paths()
        local codelldb = nix.codelldb or "codelldb"

        -- `mason-nvim-dap` used to register this adapter.
        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = codelldb,
                args = { "--port", "${port}" },
            },
        }

        local function launch_config()
            return {
                {
                    name = "LLDB: Launch",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = {},
                    console = "integratedTerminal",
                },
                {
                    name = "LLDB: Launch (args)",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = function()
                        return vim.split(vim.fn.input("Args: "), " +", { trimempty = true })
                    end,
                    console = "integratedTerminal",
                },
            }
        end

        for _, filetype in ipairs({ "c", "cpp", "rust", "swift", "zig" }) do
            dap.configurations[filetype] = launch_config()
        end
    end,
    optional = true,
}
