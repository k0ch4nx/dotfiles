---@module "lazy"
---@type LazySpec
return {
    ---@module "lazy-local-patcher"
    "polirritmico/lazy-local-patcher.nvim",
    ---@type LazyLocalPatcher.Options
    opts = {},
    lazy = false,
    config = function(self, opts)
        local main = require("lazy-local-patcher")
        local patcher = require("lazy-local-patcher.patcher")

        local git_execute = patcher.git_execute

        patcher.git_execute = function(path, cmd, error_level)
            local result = git_execute(path, cmd, error_level)

            if not result.success then
                local message = ("failed to run git %s in %s\n%s"):format(
                    table.concat(cmd, " "),
                    path,
                    result.output
                )

                vim.notify("[lazy-local-patcher] " .. message, vim.log.levels.ERROR)
                error(message, 0)
            end

            return result
        end

        main.setup(opts)

        local paths = main.options

        local function collect_patches()
            local patches = {}

            for patch in vim.fs.dir(paths.patches_path, { depth = 2 }) do
                if patch:match("%.patch$") ~= nil then
                    table.insert(patches, patch)
                end
            end

            table.sort(patches)

            return patches
        end

        local function reverse_all()
            local patches = collect_patches()

            for index = #patches, 1, -1 do
                local patch = patches[index]
                local patch_path = paths.patches_path .. "/" .. patch
                local repo_path = paths.lazy_path .. "/" .. patch:gsub("/.*", ""):gsub("%.patch$", "")
                local check = { "apply", "--reverse", "--check", "--ignore-space-change", patch_path }

                if git_execute(repo_path, check).success then
                    patcher.git_execute(repo_path, {
                        "apply",
                        "--reverse",
                        "--ignore-space-change",
                        patch_path,
                    })
                end
            end
        end

        local group = vim.api.nvim_create_augroup("DotfilesLazyLocalPatcher", {})

        vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "LazyRestorePre",
            callback = reverse_all,
        })

        vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "LazyRestore",
            callback = function()
                main.apply_all()
            end,
        })
    end,
}
