local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"

---@return string[]
local function collect_bundles()
    local bundles = {}

    vim.list_extend(
        bundles,
        vim.fn.glob(
            mason_packages
            .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
            true,
            true
        )
    )

    local java_test_patterns = {
        mason_packages .. "/java-test/extension/server/*.jar",
    }

    local excluded = {
        ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
        ["jacocoagent.jar"] = true,
    }

    for _, pattern in ipairs(java_test_patterns) do
        local jars = vim.fn.glob(pattern, true, true)

        for _, jar in ipairs(jars) do
            local name = vim.fn.fnamemodify(jar, ":t")

            if not excluded[name] then
                table.insert(bundles, jar)
            end
        end
    end

    return bundles
end

---@param callback fun(adapter: table)
local function start_debug_session(callback)
    local clients = vim.lsp.get_clients({
        name = "jdtls",
        bufnr = vim.api.nvim_get_current_buf(),
    })

    if #clients == 0 then
        vim.notify("jdtls client not found", vim.log.levels.ERROR)
        return
    end

    local client = clients[1]

    client:request("workspace/executeCommand", {
        command = "vscode.java.startDebugSession",
        arguments = {},
    }, function(err, result)
        if err then
            vim.notify(
                "Failed to start Java debug session: " .. vim.inspect(err),
                vim.log.levels.ERROR
            )
            return
        end

        local port = tonumber(type(result) == "table" and result.port or result)

        if not port then
            vim.notify(
                "Invalid Java debug port: " .. vim.inspect(result),
                vim.log.levels.ERROR
            )
            return
        end

        callback({
            type = "server",
            host = "127.0.0.1",
            port = port,
        })
    end)
end

local function setup_java_dap()
    local ok, dap = pcall(require, "dap")
    if not ok then
        return
    end

    dap.adapters.java = start_debug_session
    dap.configurations.java = dap.configurations.java or {}
end

---@param ctx lsp.HandlerContext
local function enable_inlay_hints(_, result, ctx, _)
    if not (result and result.type == "ServiceReady") then
        return
    end

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client then
        return
    end

    for bufnr, attached in pairs(client.attached_buffers) do
        if attached then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end
end

---@type vim.lsp.Config
return {
    init_options = {
        bundles = collect_bundles(),
    },
    handlers = {
        ["language/status"] = enable_inlay_hints,
    },
    on_attach = function()
        setup_java_dap()
    end,
}
