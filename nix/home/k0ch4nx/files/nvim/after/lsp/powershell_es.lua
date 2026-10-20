local nix = require("util").nix_paths()

---@type vim.lsp.Config
return {
    bundle_path = nix.powershell_bundle,
}
