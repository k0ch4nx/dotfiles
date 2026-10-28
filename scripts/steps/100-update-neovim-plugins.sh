#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() {
    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]]; then
        nvim \
            --headless \
            -c 'luafile -' <<'LUA'
local ok, err = pcall(vim.cmd, "Lazy! sync")
if not ok then
    print(err)
    vim.cmd("cquit")
else
    vim.cmd("qa")
end
LUA
        return
    fi

    nvim \
        --headless \
        --cmd 'luafile -' \
        -c 'lua local f = update_neovim_lock; if type(f) ~= "function" then io.stderr:write("100-update-neovim-plugins: hook failed to load\n"); vim.cmd("cquit 1") else f() end' <<'LUA'
local function fail(message)
    io.stderr:write("100-update-neovim-plugins: " .. message .. "\n")
    vim.cmd("cquit 1")
end

local function latch()
    local names = {}
    local seen = {}
    for _, failure in ipairs(_G.__nvim_sync_failures or {}) do
        local name = failure.plugin .. "/" .. failure.task
        if not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    return names
end

local function install_hook()
    if _G.__nvim_sync_hook then
        return
    end
    local ok, err = pcall(function()
        local Task = require("lazy.manage.task")
        if type(Task.spawn) ~= "function" or type(Task.error) ~= "function" then
            error("Task.spawn/Task.error is unavailable")
        end

        local spawn = Task.spawn
        Task.spawn = function(self, cmd, opts)
            local spawned = spawn(self, cmd, opts)
            if spawned == false then
                self:error("subprocess failed")
            end
            return spawned
        end

        local task_error = Task.error
        Task.error = function(self, msg)
            local failures = _G.__nvim_sync_failures or {}
            failures[#failures + 1] = {
                plugin = self.plugin and self.plugin.name or "?",
                task = self.name or "?",
            }
            _G.__nvim_sync_failures = failures
            return task_error(self, msg)
        end

        _G.__nvim_sync_hook = true
    end)
    if not ok then
        _G.__nvim_sync_hook_error = "could not install lazy.nvim hook: " .. tostring(err)
    end
end

-- Fires after Config.options is initialized but before Loader.install_missing.
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyPlugins",
    once = true,
    callback = install_hook,
})

local function run()
    local ok_lazy, lazy = pcall(require, "lazy")
    if not ok_lazy or type(lazy) ~= "table" then
        fail("lazy.nvim is not available")
    end
    if vim.fn.exists(":Lazy") ~= 2 then
        fail("lazy.nvim is not configured")
    end
    if not _G.__nvim_sync_hook then
        fail(_G.__nvim_sync_hook_error or "lazy.nvim failure hook did not run before startup")
    end

    local before = latch()
    if #before > 0 then
        fail("plugin synchronization failed before sync: " .. table.concat(before, ", "))
    end

    local ok_sync = pcall(vim.cmd, "Lazy! sync")
    if not ok_sync then
        local names = latch()
        local message = "`Lazy! sync` failed"
        if #names > 0 then
            message = message .. ": " .. table.concat(names, ", ")
        end
        fail(message)
    end
    local after = latch()
    if #after > 0 then
        fail("plugin synchronization failed: " .. table.concat(after, ", "))
    end

    vim.cmd("qa")
end

function update_neovim_lock()
    local ok, err = pcall(run)
    if not ok then
        fail("unexpected error: " .. tostring(err))
    end
end
LUA
}

main
