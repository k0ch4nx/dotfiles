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
                return lsp_map.lspconfig_to_package[alias]
            end

            local targets = util.table.unique(
                vim.tbl_map(to_package_name, require("mason-lspconfig.settings").current.ensure_installed),
                require("mason-null-ls.settings").current.ensure_installed,
                require("mason-nvim-dap.settings").current.ensure_installed
            )

            local done = 0
            local total = 0

            local function make_installer(pkg_name)
                local pkg = registry.get_package(pkg_name)
                return function()
                    local installed_version = pkg:get_installed_version()
                    local latest_version = pkg:get_latest_version()

                    if (installed_version and installed_version == latest_version) or pkg:is_installing() or pkg:is_uninstalling() then
                        return
                    end
                    total = total + 1
                    async.wait(function(resolve)
                        pkg:install({}, function(success, err)
                            done = done + 1
                            print(("[%" .. #tostring(total) .. "d/%d] %s %s -> %s"):format(
                                done,
                                total,
                                pkg.name,
                                installed_version or "-",
                                latest_version
                            ))
                            resolve({ success, pkg, err })
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
            max_concurrent_installers = math.huge,
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
