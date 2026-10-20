---@module "lazy"
---@type LazySpec
return {
    ---@module "lint"
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    config = function()
        local lint = require("lint")

        -- `npm-groovy-lint` has no built-in equivalent in nvim-lint.
        lint.linters.npm_groovy_lint = {
            name = "npm_groovy_lint",
            cmd = "npm-groovy-lint",
            stdin = false,
            append_fname = true,
            args = function()
                local args = { "--failon", "none", "-o", "json" }

                -- https://github.com/nvuillam/npm-groovy-lint/issues/422#issuecomment-2324321544
                if vim.fn.expand("%:t") == "Jenkinsfile" then
                    table.insert(args, "--no-parse")
                end

                return args
            end,
            ignore_exitcode = true,
            parser = function(output)
                local ok, decoded = pcall(vim.json.decode, output)

                if not ok or type(decoded) ~= "table" or type(decoded.files) ~= "table" then
                    return {}
                end

                local diagnostics = {}

                for _, file in pairs(decoded.files) do
                    for _, err in ipairs(file.errors or {}) do
                        local range = err.range or {}
                        local start = range.start or {}
                        local finish = range["end"] or {}

                        table.insert(diagnostics, {
                            lnum = math.max((start.line or err.line or 1) - 1, 0),
                            end_lnum = math.max((finish.line or err.line or 1) - 1, 0),
                            col = start.character or 0,
                            end_col = finish.character or 0,
                            message = err.msg,
                            code = err.rule,
                            severity = err.severity == "error" and vim.diagnostic.severity.ERROR
                                or err.severity == "warning" and vim.diagnostic.severity.WARN
                                or vim.diagnostic.severity.INFO,
                        })
                    end
                end

                return diagnostics
            end,
        }

        -- `mason-null-ls` used to register these diagnostics through none-ls.
        -- `oxlint` and `ruff` are omitted because their LSP servers already report.
        lint.linters_by_ft = {
            dockerfile = { "hadolint", "trivy" },
            groovy = { "npm_groovy_lint" },
            Jenkinsfile = { "npm_groovy_lint" },
            java = { "checkstyle" },
            nix = { "statix" },
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            zsh = { "shellcheck" },
            sql = { "sqruff" },
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
    end,
}
