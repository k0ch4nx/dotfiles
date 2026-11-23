local nix = require("util").nix_paths()

---@type vim.lsp.Config
return {
    init_options = {
        typescript = {
            enabled = true,
            tsdk = nix.typescript_tsdk,
        },
    },
}
