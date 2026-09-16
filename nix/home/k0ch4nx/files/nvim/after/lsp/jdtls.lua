local mason_root = vim.fn.stdpath("data") .. "/mason"
local mason_packages = mason_root .. "/packages"
local lombok_jar = mason_root .. "/share/jdtls/lombok.jar"

local function nix_build(package)
    local result = vim.system({
        "nix",
        "build",
        "nixpkgs#" .. package,
        "--no-link",
        "--print-out-paths",
    }, { text = true }):wait()

    if result.code ~= 0 then
        error("Failed to get " .. package .. ": " .. result.stderr)
    end

    return vim.trim(result.stdout)
end

local jdtls_java_home = nix_build("temurin-bin-25")
local project_java_home = nix_build("temurin-bin-17")

local java_root_markers = {
    { "settings.gradle", "settings.gradle.kts" },
    { "gradlew", "build.gradle", "build.gradle.kts", "mvnw", "pom.xml", "build.xml" },
}

---@type vim.lsp.Config
return {
    root_dir = function(bufnr, on_dir)
        local root = vim.fs.root(bufnr, java_root_markers)

        if root then
            on_dir(root)
        end
    end,
    cmd = function(dispatchers, config)
        local root = config.root_dir or vim.fn.getcwd()
        local data_dir = string.format(
            "%s/jdtls/workspace/%s-%s",
            vim.fn.stdpath("cache"),
            vim.fs.basename(root),
            vim.fn.sha256(root):sub(1, 8)
        )

        return vim.lsp.rpc.start({
            vim.fn.exepath("jdtls"),
            "-data",
            data_dir,
            "--java-executable",
            jdtls_java_home .. "/bin/java",
            "--jvm-arg=-javaagent:" .. lombok_jar,
        }, dispatchers, {
            cwd = config.cmd_cwd,
            env = config.cmd_env,
            detached = config.detached,
        })
    end,
    cmd_env = vim.tbl_extend("force", vim.fn.environ(), {
        JAVA_HOME = project_java_home,
    }),
    settings = {
        java = {
            configuration = {
                runtimes = {
                    {
                        name = "JavaSE-17",
                        path = project_java_home,
                        default = true,
                    },
                },
            },
            import = {
                gradle = {
                    java = {
                        home = project_java_home,
                    },
                },
            },
        },
    },
    init_options = {
        bundles = (function()
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

            return bundles
        end)(),
    },
    handlers = {
        ---@param ctx lsp.HandlerContext
        ["language/status"] = function(_, result, ctx, _)
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
        end,
    },
    on_attach = function()
        local ok, dap = pcall(require, "dap")
        if not ok then
            return
        end

        dap.adapters.java = function(callback)
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
                    vim.notify("Failed to start Java debug session: " .. vim.inspect(err), vim.log.levels.ERROR)
                    return
                end

                local port = tonumber(type(result) == "table" and result.port or result)

                if not port then
                    vim.notify("Invalid Java debug port: " .. vim.inspect(result), vim.log.levels.ERROR)
                    return
                end

                callback({
                    type = "server",
                    host = "127.0.0.1",
                    port = port,
                })
            end)
        end

        dap.configurations.java = dap.configurations.java or {}
    end,
}
