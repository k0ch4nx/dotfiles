local util = require("util")

---@module "lazy"
---@type LazySpec
return {
    ---@module "mason"
    "williamboman/mason.nvim",
    ---@param opts MasonSettings
    opts = function(self, opts)
        vim.api.nvim_create_user_command("MasonInstallAll", function()
            local async = require("mason-core.async")
            local lsp_map = require("mason-lspconfig.mappings").get_mason_map()
            local registry = require("mason-registry")

            local function to_package_name(alias)
                local package_name = lsp_map.lspconfig_to_package[alias]

                assert(package_name, ("Mason package not found for %q"):format(alias))

                return package_name
            end

            local dap_map = require("mason-nvim-dap.mappings.source").nvim_dap_to_package

            local function to_dap_package_name(alias)
                return dap_map[alias] or alias
            end

            local targets = util.table.unique(
                vim.tbl_map(
                    to_package_name,
                    require("mason-lspconfig.settings").current.ensure_installed
                ),
                { "snyk" },
                require("mason-null-ls.settings").current.ensure_installed,
                vim.tbl_map(
                    to_dap_package_name,
                    require("mason-nvim-dap.settings").current.ensure_installed
                )
            )

            local failures = {}
            local packages = {}
            local done = 0
            local total = 0

            local function record_failure(package_name, err)
                table.insert(failures, ("%s: %s"):format(package_name, tostring(err)))
            end

            local function wait_until(predicate, timeout)
                local deadline = vim.uv.now() + timeout

                while not predicate() do
                    if vim.uv.now() >= deadline then
                        return false
                    end

                    async.sleep(100)
                end

                return true
            end

            local function make_installer(package)
                return function()
                    local installed_version = package:get_installed_version()
                    local latest_version = package:get_latest_version()

                    if installed_version and installed_version == latest_version then
                        return
                    end

                    local function is_idle()
                        return not package:is_installing() and not package:is_uninstalling()
                    end

                    if not wait_until(is_idle, 10 * 60 * 1000) then
                        record_failure(package.name, "timed out waiting for an install to finish")

                        return
                    end

                    installed_version = package:get_installed_version()

                    if installed_version and installed_version == latest_version then
                        return
                    end

                    total = total + 1

                    async.wait(function(resolve)
                        package:install({}, function(success, err)
                            done = done + 1

                            print(
                                ("[%" .. #tostring(total) .. "d/%d] %s %s -> %s"):format(
                                    done,
                                    total,
                                    package.name,
                                    installed_version or "-",
                                    latest_version
                                )
                            )

                            if not success then
                                record_failure(package.name, err)
                            end

                            resolve({ success, package, err })
                        end)
                    end)
                end
            end

            async.run_blocking(function()
                local refreshed, refresh_err = async.wait(function(resolve)
                    registry.refresh(function(success, result)
                        resolve(success, result)
                    end)
                end)

                if not refreshed then
                    vim.notify(
                        ("[mason] Registry refresh failed: %s"):format(refresh_err),
                        vim.log.levels.WARN
                    )
                end

                for _, target in ipairs(targets) do
                    local ok, package = pcall(registry.get_package, target)

                    if ok then
                        table.insert(packages, package)
                    else
                        record_failure(target, package)
                    end
                end

                async.wait_all(vim.tbl_map(make_installer, packages))
                async.scheduler()
            end)

            for _, package in ipairs(packages) do
                if not package:is_installed() then
                    record_failure(package.name, "not installed")
                end
            end

            if #failures > 0 then
                error(("[mason] MasonInstallAll failed:\n%s"):format(table.concat(failures, "\n")), 0)
            end
        end, {})

        return {
            max_concurrent_installers = 8,
            ui = {
                border = "rounded",
                backdrop = 100,
                height = 0.8,
            },
        }
    end,
    -- https://github.com/mason-org/mason.nvim?tab=readme-ov-file#installation--usage
    lazy = false,
}
