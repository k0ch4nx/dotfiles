{ config, lib, ... }:

let
  cfg = config.dotfiles.nixCache;
  cache = import ../../r2-cache.nix;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  r2Cache = "s3://${cfg.bucket}?endpoint=${cfg.accountId}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=${cache.profile}";
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
      default = cache.accountId;
      description = "Cloudflare account ID used to construct the private R2 endpoint.";
    };

    bucket = mkOption {
      type = types.str;
      default = cache.bucket;
      description = "R2 bucket containing the Nix binary cache.";
    };

    localPublicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public half of the nix-cache-local-1 signing key.";
    };

    ciPublicKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public half of the nix-cache-ci-1 signing key.";
    };

    credentialsSecret = mkOption {
      type = types.path;
      default = ../../../secrets/r2-credentials.age;
      description = "agenix-rekey file containing the shared nix-cache AWS profile.";
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
          assertion = cfg.localPublicKey != null && lib.hasPrefix "nix-cache-local-1:" cfg.localPublicKey;
          message = "dotfiles.nixCache.localPublicKey must be the nix-cache-local-1 public key.";
        }
        {
          assertion = cfg.ciPublicKey != null && lib.hasPrefix "nix-cache-ci-1:" cfg.ciPublicKey;
          message = "dotfiles.nixCache.ciPublicKey must be the nix-cache-ci-1 public key.";
        }
        {
          assertion = builtins.pathExists cfg.credentialsSecret;
          message = "The R2 credentials age file does not exist.";
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
      };

      nix.envVars.AWS_SHARED_CREDENTIALS_FILE = "/var/root/.aws/credentials";
    })
  ];
}
