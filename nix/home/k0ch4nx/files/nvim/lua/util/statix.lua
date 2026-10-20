local M = {}

---@param actions table[]
local function select_action(actions)
    vim.ui.select(actions, {
        prompt = "Statix fixes",
        format_item = function(action)
            return action.title
        end,
    }, function(action)
        if not action then
            return
        end

        vim.api.nvim_buf_set_text(
            action.bufnr,
            action.from.line - 1,
            action.from.column - 1,
            action.to.line - 1,
            action.to.column - 1,
            action.fix
        )
    end)
end

---Reimplements none-ls' `code_actions.statix` without the none-ls client.
function M.code_actions()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"

    vim.system({ "statix", "check", "--stdin", "--format=json" }, { stdin = input, text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 and result.code ~= 1 then
                vim.notify("statix: " .. (result.stderr or "failed"), vim.log.levels.ERROR)
                return
            end

            local ok, decoded = pcall(vim.json.decode, result.stdout or "")

            if not ok or type(decoded) ~= "table" then
                return
            end

            local actions = {}

            for _, report in ipairs(decoded.report or {}) do
                for _, diagnostic in ipairs(report.diagnostics or {}) do
                    local suggestion = diagnostic.suggestion

                    if suggestion and suggestion ~= vim.NIL and suggestion.at then
                        local from = suggestion.at.from
                        local to = suggestion.at.to

                        if from.line <= row and row <= to.line then
                            local fix = {}

                            for line in vim.gsplit(suggestion.fix, "\n", { plain = true }) do
                                table.insert(fix, line)
                            end

                            table.insert(actions, {
                                bufnr = bufnr,
                                title = "Fix: " .. diagnostic.message,
                                from = from,
                                to = to,
                                fix = fix,
                            })
                        end
                    end
                end
            end

            if #actions == 0 then
                vim.notify("No statix fixes at the cursor", vim.log.levels.INFO)
                return
            end

            select_action(actions)
        end)
    end)
end

return M
