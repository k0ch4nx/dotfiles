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
      r2-credentials = {
        rekeyFile = ../../../secrets/r2-credentials.age;
        path = "${cacheDirectory}/credentials";
        mode = "600";
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
    R2_CREDENTIALS_FILE = config.age.secrets.r2-credentials.path;
    NIX_CACHE_PRIVATE_KEY_FILE = config.age.secrets.nix-cache-local-private-key.path;
  };
}
