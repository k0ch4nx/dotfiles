{
  config,
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  host = cache.hosts.ubuntu-wsl;
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

  users.groups.keys = { };

  nix.settings = cache.mkNixSettings lib;

  environment.etc."systemd/system/nix-daemon.service.d/r2-cache.conf" = {
    mode = "0644";
    text = ''
      [Service]
      Environment="AWS_SHARED_CREDENTIALS_FILE=${host.credentialsFile}"
    '';
  };

  age = lib.mkIf (!cache.isGitHubActions) {
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

    secrets = cache.mkCredentialsSecrets {
      inherit config;
      credentialsFile = host.credentialsFile;
      group = host.credentialsGroup;
    };
  };

  assertions = lib.optionals (!cache.isGitHubActions) cache.secretAssertions;
}
