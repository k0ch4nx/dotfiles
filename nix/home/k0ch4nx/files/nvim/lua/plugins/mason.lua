local util = require("util.init")

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

            local targets = util.table.unique(
                vim.tbl_map(
                    to_package_name,
                    require("mason-lspconfig.settings").current.ensure_installed
                ),
                { "snyk" },
                require("mason-null-ls.settings").current.ensure_installed,
                require("mason-nvim-dap.settings").current.ensure_installed
            )

            local done = 0
            local total = 0

            local function make_installer(package_name)
                local package = registry.get_package(package_name)

                return function()
                    local installed_version = package:get_installed_version()
                    local latest_version = package:get_latest_version()

                    if
                        (installed_version and installed_version == latest_version)
                        or package:is_installing()
                        or package:is_uninstalling()
                    then
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

                            resolve({ success, package, err })
                        end)
                    end)
                end
            end

            registry.refresh()

            async.run_blocking(function()
                async.wait_all(vim.tbl_map(make_installer, targets))
                async.scheduler()
            end)
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
