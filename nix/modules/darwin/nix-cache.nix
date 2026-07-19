{ config, lib, ... }:

let
  cfg = config.dotfiles.nixCache;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  r2Cache = "s3://${cfg.bucket}?endpoint=${cfg.accountId}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=nix-cache";
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
  options.dotfiles.nixCache = {
    enable = mkEnableOption "the private Cloudflare R2 Nix binary cache";

    accountId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Cloudflare account ID used to construct the private R2 endpoint.";
    };

    bucket = mkOption {
      type = types.str;
      default = "dotfiles-nix-cache";
      description = "R2 bucket containing the Nix binary cache.";
    };

    localPublicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public half of the dotfiles-r2-local-1 signing key.";
    };

    ciPublicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public half of the dotfiles-r2-ci-1 signing key.";
    };

    credentialsSecret = mkOption {
      type = types.path;
      default = ../../../secrets/r2-credentials.age;
      description = "agenix-rekey file containing the shared nix-cache AWS profile.";
    };

    localPrivateKeySecret = mkOption {
      type = types.path;
      default = ../../../secrets/nix-cache-local-private-key.age;
      description = "agenix-rekey file containing the local Nix cache signing key.";
    };
  };

  config = lib.mkMerge [
    {
      nix.settings = {
        substituters = lib.mkForce (lib.optionals cfg.enable [ r2Cache ] ++ standardSubstituters);
        trusted-public-keys = lib.mkForce (
          lib.optionals cfg.enable [
            cfg.localPublicKey
            cfg.ciPublicKey
          ]
          ++ standardPublicKeys
        );
        fallback = true;
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.accountId != null && cfg.accountId != "";
          message = "dotfiles.nixCache.accountId must be set when the R2 cache is enabled.";
        }
        {
          assertion = cfg.localPublicKey != null && lib.hasPrefix "dotfiles-r2-local-1:" cfg.localPublicKey;
          message = "dotfiles.nixCache.localPublicKey must be the dotfiles-r2-local-1 public key.";
        }
        {
          assertion = cfg.ciPublicKey != null && lib.hasPrefix "dotfiles-r2-ci-1:" cfg.ciPublicKey;
          message = "dotfiles.nixCache.ciPublicKey must be the dotfiles-r2-ci-1 public key.";
        }
        {
          assertion = builtins.pathExists cfg.credentialsSecret;
          message = "The R2 credentials age file does not exist.";
        }
        {
          assertion = builtins.pathExists cfg.localPrivateKeySecret;
          message = "The local Nix cache private key age file does not exist.";
        }
      ];

      age.secrets = {
        r2-root-credentials = {
          rekeyFile = cfg.credentialsSecret;
          path = "/var/root/.aws/credentials";
          owner = "root";
          group = "wheel";
          mode = "600";
        };

        r2-user-credentials = {
          rekeyFile = cfg.credentialsSecret;
          path = "/run/agenix/r2-credentials";
          owner = config.system.primaryUser;
          group = "staff";
          mode = "600";
        };

        nix-cache-local-private-key = {
          rekeyFile = cfg.localPrivateKeySecret;
          path = "/run/agenix/nix-cache-local-private-key";
          owner = config.system.primaryUser;
          group = "staff";
          mode = "600";
        };
      };

      nix.envVars.AWS_SHARED_CREDENTIALS_FILE = "/var/root/.aws/credentials";
    })
  ];
}
