{
  config,
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  system = cache.systems.x86_64-linux;
  resolvedDotfilesDir = import ../dotfiles-dir.nix {
    fallback = "/home/k0ch4nx/src/github.com/k0ch4nx/dotfiles";
  };
in
{
  imports = [
    flake.modules.system-manager.agenix-compat
    flake.modules.system-manager.agenix-rekey
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  config = {
    users.groups.keys = { };

    nix.settings = cache.mkNixSettings lib;

    environment.etc."systemd/system/nix-daemon.service.d/r2-cache.conf" = {
      mode = "0644";
      text = ''
        [Service]
        Environment="AWS_SHARED_CREDENTIALS_FILE=${system.credentialsFile}"
      '';
    };

    age = lib.optionalAttrs (!cache.isGitHubActions) {
      identityPaths = [
        "${resolvedDotfilesDir}/secrets/hosts/ubuntu-wsl-k0ch4nx-key.txt"
      ];

      secrets = cache.mkCredentialsSecrets {
        inherit config;
        inherit (system) credentialsFile;
        group = system.credentialsGroup;
      };
    };

    assertions = lib.optionals (!cache.isGitHubActions) cache.secretAssertions;
  };
}
