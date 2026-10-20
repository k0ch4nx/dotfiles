---@module "lazy"
---@type LazySpec
return {
    ---@module "lint"
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    config = function()
        local lint = require("lint")

        -- nvim-lint ships a stdin-based npm-groovy-lint linter.
        -- Jenkinsfiles additionally need `--no-parse`.
        lint.linters.npm_groovy_lint = function()
            local linter = vim.deepcopy(lint.linters["npm-groovy-lint"])

            if vim.fn.expand("%:t") == "Jenkinsfile" then
                table.insert(linter.args, 1, "--no-parse")
            end

            return linter
        end

        -- `terraform validate` reports the whole module. The built-in parser
        -- mislabels cross-file diagnostics, so rebuild it and keep only the
        -- diagnostics that belong to the current buffer.
        lint.linters.terraform_validate = function()
            local severity = {
                notice = vim.diagnostic.severity.INFO,
                warning = vim.diagnostic.severity.WARN,
                error = vim.diagnostic.severity.ERROR,
            }

            return {
                cmd = "terraform",
                args = {
                    function()
                        return "-chdir=" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.:h")
                    end,
                    "validate",
                    "-json",
                },
                append_fname = false,
                stdin = false,
                stream = "stdout",
                ignore_exitcode = true,
                parser = function(output, bufnr)
                    local ok, decoded = pcall(vim.json.decode, output)

                    if not ok or type(decoded) ~= "table" then
                        return {}
                    end

                    local buf_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
                    local diagnostics = {}

                    for _, diagnostic in ipairs(decoded.diagnostics or {}) do
                        local range = diagnostic.range

                        if range and range.filename == buf_path then
                            local message = diagnostic.summary or ""

                            if diagnostic.detail then
                                message = message .. " - " .. diagnostic.detail
                            end

                            table.insert(diagnostics, {
                                lnum = tonumber(range.start.line) - 1,
                                col = tonumber(range.start.column) - 1,
                                end_lnum = tonumber(range["end"].line) - 1,
                                end_col = tonumber(range["end"].column) - 1,
                                message = message,
                                source = "terraform validate",
                                severity = severity[diagnostic.severity] or vim.diagnostic.severity.ERROR,
                            })
                        end
                    end

                    return diagnostics
                end,
            }
        end

        -- `mason-null-ls` used to register these diagnostics through none-ls.
        -- `oxlint` and `ruff` are omitted because their LSP servers already report.
        lint.linters_by_ft = {
            bash = { "shellcheck" },
            bzl = { "buildifier" },
            dockerfile = { "hadolint", "trivy" },
            groovy = { "npm_groovy_lint" },
            helm = { "trivy" },
            java = { "checkstyle" },
            nix = { "statix" },
            sh = { "shellcheck" },
            sql = { "sqruff" },
            starlark = { "buildifier" },
            terraform = { "terraform_validate", "trivy" },
            tf = { "terraform_validate", "trivy" },
            ["terraform-vars"] = { "terraform_validate", "trivy" },
            yaml = { "yamllint" },
        }

        local group = vim.api.nvim_create_augroup("DotfilesNvimLint", { clear = true })

        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            group = group,
            callback = function()
                lint.try_lint()
            end,
        })

        -- none-ls used to expose statix fixes through the code-action menu.
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "nix",
            callback = function(event)
                vim.keymap.set("n", "<Leader>ca", function()
                    require("util.statix").code_actions()
                end, { buffer = event.buf, desc = "Statix fixes" })
            end,
        })
    end,
}
