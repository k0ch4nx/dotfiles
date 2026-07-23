{
  config,
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  credentialsFile = cache.rootCredentialsFile.linux;
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  resolvedDotfilesDir =
    if dotfilesDir != "" then
      dotfilesDir
    else
      "/home/k0ch4nx/src/github.com/k0ch4nx/dotfiles";
  hostPubkeyPath = ../../../secrets/hosts/ubuntu-wsl-k0ch4nx.pub;
  hostPubkey =
    if builtins.pathExists hostPubkeyPath then
      builtins.readFile hostPubkeyPath
    else
      null;
in
{
  imports = [
    flake.modules.system-manager.agenix-compat
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  assertions = [
    {
      assertion = builtins.pathExists ../../../secrets/r2-access-key-id.age;
      message = "The R2 access key ID age file does not exist.";
    }
    {
      assertion = builtins.pathExists ../../../secrets/r2-secret-access-key.age;
      message = "The R2 secret access key age file does not exist.";
    }
  ];

  users.groups.keys = { };

  age = {
    rekey = {
      storageMode = "derivation";
      cacheDir = "/var/tmp/agenix-rekey-k0ch4nx";
      masterIdentities = [
        ../../../secrets/master/yubikey-identity.pub
      ];
    }
    // lib.optionalAttrs (hostPubkey != null) {
      inherit hostPubkey;
    };

    identityPaths = [
      "${resolvedDotfilesDir}/secrets/hosts/ubuntu-wsl-k0ch4nx-key.txt"
    ];

    secrets = {
      r2-root-access-key-id = {
        rekeyFile = ../../../secrets/r2-access-key-id.age;
        intermediary = true;
      };

      r2-root-secret-access-key = {
        rekeyFile = ../../../secrets/r2-secret-access-key.age;
        intermediary = true;
      };

      r2-root-credentials = {
        rekeyFile = ../../../secrets/r2-credentials.age;
        generator = cache.credentialsGenerator {
          accessKeySecret = config.age.secrets.r2-root-access-key-id;
          secretKeySecret = config.age.secrets.r2-root-secret-access-key;
        };
        path = credentialsFile;
        owner = "root";
        group = "root";
        mode = "600";
      };
    };
  };

  nix.settings = {
    substituters = lib.mkForce cache.substituters;
    trusted-public-keys = lib.mkForce cache.trustedPublicKeys;
    fallback = true;
  };

  environment.etc."systemd/system/nix-daemon.service.d/r2-cache.conf" = {
    mode = "0644";
    text = ''
      [Service]
      Environment="AWS_SHARED_CREDENTIALS_FILE=${credentialsFile}"
    '';
  };
}
