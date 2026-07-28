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
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  resolvedDotfilesDir =
    if dotfilesDir != "" then dotfilesDir else "/home/k0ch4nx/src/github.com/k0ch4nx/dotfiles";
  hostPubkeyPath = ../../../secrets/hosts/ubuntu-wsl-k0ch4nx.pub;
  hostPubkey = if builtins.pathExists hostPubkeyPath then builtins.readFile hostPubkeyPath else null;
in
{
  imports = [
    flake.modules.system-manager.agenix-compat
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  options.dotfiles.agenixRekey.localStorageDir = lib.mkOption {
    type = lib.types.path;
    description = "Git-tracked directory containing this system-manager configuration's rekeyed age files.";
  };

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

    age = {
      rekey = {
        storageMode = "local";
        localStorageDir = config.dotfiles.agenixRekey.localStorageDir;
        masterIdentities = [
          ../../../secrets/master/yubikey-identity.pub
        ];
      }
      // lib.optionalAttrs (hostPubkey != null) {
        inherit hostPubkey;
      };
    }
    // lib.optionalAttrs (!cache.isGitHubActions) {
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
