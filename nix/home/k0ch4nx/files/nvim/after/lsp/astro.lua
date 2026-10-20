local nix = require("util").nix_paths()

---@type vim.lsp.Config
return {
    init_options = {
        -- TypeScript 7 dropped `tsserverlibrary.js`, so pin the Astro server
        -- to the packaged TypeScript 5 SDK.
        typescript = {
            tsdk = nix.typescript_tsdk,
        },
    },
}
