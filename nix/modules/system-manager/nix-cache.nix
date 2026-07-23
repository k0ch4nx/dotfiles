{
  config,
  flake,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  credentialsFile = cache.rootCredentialsFile.linux;
  accessKeyFile = config.age.secrets.r2-root-access-key-id.path;
  secretKeyFile = config.age.secrets.r2-root-secret-access-key.path;
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  resolvedDotfilesDir =
    if dotfilesDir != "" then dotfilesDir else "/home/k0ch4nx/src/github.com/k0ch4nx/dotfiles";
  hostPubkeyPath = ../../../secrets/hosts/ubuntu-wsl-k0ch4nx.pub;
  hostPubkey = if builtins.pathExists hostPubkeyPath then builtins.readFile hostPubkeyPath else null;
  standardSubstituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];
  standardPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
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
        owner = "root";
        group = "root";
        mode = "400";
      };

      r2-root-secret-access-key = {
        rekeyFile = ../../../secrets/r2-secret-access-key.age;
        owner = "root";
        group = "root";
        mode = "400";
      };
    };
  };

  nix.settings = {
    substituters = lib.mkForce ([ cache.url ] ++ standardSubstituters);
    trusted-public-keys = lib.mkForce (
      [
        cache.localPublicKey
        cache.ciPublicKey
      ]
      ++ standardPublicKeys
    );
    fallback = true;
  };

  environment.etc."systemd/system/nix-daemon.service.d/r2-cache.conf" = {
    mode = "0644";
    text = ''
      [Service]
      Environment="AWS_SHARED_CREDENTIALS_FILE=${credentialsFile}"
    '';
  };

  systemd.services.agenix-install-secrets.postStart = ''
    accessKeyId="$(${pkgs.coreutils}/bin/cat "${accessKeyFile}")"
    secretAccessKey="$(${pkgs.coreutils}/bin/cat "${secretKeyFile}")"

    [ -n "$accessKeyId" ] || exit 1
    [ -n "$secretAccessKey" ] || exit 1
    [ "''${#accessKeyId}" -eq 32 ] || exit 1
    [ "''${#secretAccessKey}" -eq 64 ] || exit 1

    ${pkgs.coreutils}/bin/install -d -m 700 -o root -g root "$(${pkgs.coreutils}/bin/dirname "${credentialsFile}")"
    temporaryFile="$(${pkgs.coreutils}/bin/mktemp "${credentialsFile}.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$temporaryFile"' EXIT HUP INT TERM

    printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
      "$accessKeyId" \
      "$secretAccessKey" >"$temporaryFile"
    ${pkgs.coreutils}/bin/chown root:root "$temporaryFile"
    ${pkgs.coreutils}/bin/chmod 600 "$temporaryFile"
    ${pkgs.coreutils}/bin/mv -f "$temporaryFile" "${credentialsFile}"
    trap - EXIT HUP INT TERM
  '';
}
