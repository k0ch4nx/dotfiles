{
  config,
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  system = cache.systems.aarch64-darwin;
  resolvedDotfilesDir = import ../dotfiles-dir.nix {
    fallback = "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles";
  };
in
{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
    flake.modules.agenix.rekey
  ];

  config = lib.mkMerge [
    {
      nix.settings = cache.mkNixSettings lib;

      launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
        AWS_SHARED_CREDENTIALS_FILE = system.credentialsFile;
      };
    }

    (lib.mkIf (!cache.isGitHubActions) {
      assertions = cache.secretAssertions;

      age = {
        identityPaths = [
          "${resolvedDotfilesDir}/secrets/hosts/macbook-pro-k0ch4nx-key.txt"
        ];

        secrets = cache.mkCredentialsSecrets {
          inherit config;
          inherit (system) credentialsFile;
          group = system.credentialsGroup;
        };
      };
    })
  ];
}
