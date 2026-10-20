local nix = require("util").nix_paths()

---@type vim.lsp.Config
return {
    init_options = {
        typescript = {
            tsdk = nix.typescript_tsdk,
        },
    },
}
