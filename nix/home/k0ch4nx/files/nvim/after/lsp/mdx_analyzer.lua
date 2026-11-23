local nix = require("util").nix_paths()

return {
    init_options = {
        typescript = {
            enabled = true,
            tsdk = nix.typescript_tsdk,
        },
    },
}
