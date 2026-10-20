local pending = {}

-- statix is a CLI, not an LSP server, so it has no diff preview.
local StatixAction = {}
StatixAction.__index = StatixAction

function StatixAction.new(item)
    return setmetatable({ item = item }, StatixAction)
end

function StatixAction:title()
    return "Fix: " .. self.item.message
end

function StatixAction:client_name()
    return "statix"
end

function StatixAction:resolve(callback)
    callback(self)
end

function StatixAction:preview(callback)
    callback(nil)
end

function StatixAction:apply()
    local item = self.item

    vim.api.nvim_buf_set_text(
        item.bufnr,
        item.from.line - 1,
        item.from.column - 1,
        item.to.line - 1,
        item.to.column - 1,
        item.fix
    )
end

local function code_actions()
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= "nix" then
        require("actions-preview").code_actions()
        return
    end

    pending = {}

    local row = vim.api.nvim_win_get_cursor(0)[1]

    require("util.statix").collect(bufnr, row, function(items)
        pending = vim.tbl_map(StatixAction.new, items)

        local clients = vim.lsp.get_clients({
            bufnr = bufnr,
            method = "textDocument/codeAction",
        })

        if #clients > 0 then
            require("actions-preview").code_actions()
            return
        end

        -- No LSP provider: still expose statix fixes.
        local actions = pending
        pending = {}

        if #actions == 0 then
            vim.notify("No code actions available", vim.log.levels.INFO)
            return
        end

        vim.ui.select(actions, {
            prompt = "Statix fixes",
            format_item = function(action)
                return action:title()
            end,
        }, function(action)
            if action then
                action:apply()
            end
        end)
    end)
end

---@module "lazy"
---@type LazySpec
return {
    "aznhe21/actions-preview.nvim",
    ---@module "actions-preview"
    dependencies = {
        ---@module "snacks"
        "folke/snacks.nvim",
    },
    init = function()
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                -- Neovim 0.11+ maps `gra` buffer-locally on attach; override it.
                vim.keymap.set({ "n", "v" }, "gra", code_actions, { buffer = ev.buf })
            end,
        })
    end,
    keys = {
        {
            "gra",
            code_actions,
            mode = { "n", "v" },
            desc = "Code actions",
        },
    },
    opts = function()
        -- Inject the collected statix actions into actions-preview's picker
        -- without forking its LSP collection or resolve logic.
        local backend = require("actions-preview.backend")

        if not backend._dotfiles_statix_patched then
            backend._dotfiles_statix_patched = true

            local select = backend.select

            backend.select = function(config, actions)
                vim.list_extend(actions, pending)
                pending = {}

                return select(config, actions)
            end
        end

        return {
            highlight_command = {
                -- https://github.com/dandavison/delta
                require("actions-preview.highlight").delta("delta --no-gitconfig --side-by-side"),
            },
            backend = { "snacks" },
            ---@type snacks.picker.Config
            snacks = {
                layout = { preset = "default" },
            },
        }
    end,
}
