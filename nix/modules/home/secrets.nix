{
  config,
  flake,
  hostName,
  inputs,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  cacheDirectory = "${config.xdg.configHome}/nix-cache";
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.agenix-rekey.homeManagerModules.default
    flake.modules.agenix.rekey
  ];

  age = {
    identityPaths = [
      "${config.dotfiles.path}/secrets/hosts/${hostName}-${config.home.username}-key.txt"
    ];

    secrets = {
      hcp-terraform-token = {
        rekeyFile = ../../../secrets/hcp-terraform-token.age;
      };
      nix-cache-local-private-key = {
        rekeyFile = ../../../secrets/nix-cache-local-private-key.age;
        path = "${cacheDirectory}/private-key";
        mode = "600";
      };
    };
  };

  home.sessionVariables = {
    CLOUDFLARE_ACCOUNT_ID = cache.accountId;
    R2_CACHE_BUCKET = cache.bucket;
    NIX_CACHE_PRIVATE_KEY_FILE = config.age.secrets.nix-cache-local-private-key.path;
  };
}
