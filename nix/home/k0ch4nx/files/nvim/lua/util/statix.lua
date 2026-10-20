local M = {}

---Collects statix fixes that overlap `row` from the current buffer content.
---@param bufnr integer
---@param row integer
---@param callback fun(actions: table[])
function M.collect(bufnr, row, callback)
    if vim.fn.executable("statix") ~= 1 then
        vim.notify_once("statix unavailable; showing LSP actions only", vim.log.levels.WARN)
        callback({})
        return
    end

    local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"

    local ok, err = pcall(vim.system, { "statix", "check", "--stdin", "--format=json" }, { stdin = input, text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 and result.code ~= 1 then
                vim.notify("statix: " .. (result.stderr or "failed"), vim.log.levels.WARN)
                callback({})
                return
            end

            local ok, decoded = pcall(vim.json.decode, result.stdout or "")

            if not ok or type(decoded) ~= "table" then
                callback({})
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
                                message = diagnostic.message,
                                from = from,
                                to = to,
                                fix = fix,
                            })
                        end
                    end
                end
            end

            callback(actions)
        end)
    end)

    if not ok then
        vim.notify("statix: " .. tostring(err), vim.log.levels.WARN)
        callback({})
    end
end

return M
