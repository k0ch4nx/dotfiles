let
  accountId = "6118f982b348f7b37129655ee4160301";
  bucket = "nix-cache";
  accessKeyFile = ../secrets/r2-access-key-id.age;
  secretKeyFile = ../secrets/r2-secret-access-key.age;
  url = "s3://${bucket}?endpoint=${accountId}.r2.cloudflarestorage.com&scheme=https&region=auto&priority=30";
  localPublicKey = "nix-cache-local:GpHBxUjXDkgtfjKeAD/cuGY8pnCjSsZhc8plkslpfFk=";
  ciPublicKey = "nix-cache-ci:8fZtfHt16O6CvXJlPH0H4uqHTs61K5iruLvTAIFIPmU=";
  substituters = [
    "https://cache.nixos.org/?priority=10"
    "https://nix-community.cachix.org?priority=20"
    url
  ];
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    localPublicKey
    ciPublicKey
  ];
  credentialsGenerator =
    {
      accessKeySecret,
      secretKeySecret,
    }:
    {
      dependencies = {
        accessKeyId = accessKeySecret;
        secretAccessKey = secretKeySecret;
      };

      script =
        {
          decrypt,
          deps,
          lib,
          ...
        }:
        ''
          accessKeyId="$(${decrypt} ${lib.escapeShellArg deps.accessKeyId.file})"
          secretAccessKey="$(${decrypt} ${lib.escapeShellArg deps.secretAccessKey.file})"

          [ -n "$accessKeyId" ]
          [ -n "$secretAccessKey" ]
          [ "''${#accessKeyId}" -eq 32 ]
          [ "''${#secretAccessKey}" -eq 64 ]

          printf \
            '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
            "$accessKeyId" \
            "$secretAccessKey"
        '';
    };
in
{
  inherit
    accountId
    bucket
    ciPublicKey
    localPublicKey
    substituters
    trustedPublicKeys
    url
    ;

  isGitHubActions = builtins.getEnv "GITHUB_ACTIONS" == "true";

  settings = {
    inherit substituters;
    trusted-public-keys = trustedPublicKeys;
    fallback = true;
  };

  hosts = {
    macbook-pro = {
      credentialsFile = "/var/root/.aws/credentials";
      credentialsGroup = "wheel";
    };

    ubuntu-wsl = {
      credentialsFile = "/root/.aws/credentials";
      credentialsGroup = "root";
    };
  };

  secretAssertions = [
    {
      assertion = builtins.pathExists accessKeyFile;
      message = "The R2 access key ID age file does not exist.";
    }
    {
      assertion = builtins.pathExists secretKeyFile;
      message = "The R2 secret access key age file does not exist.";
    }
  ];

  mkNixSettings = lib: {
    substituters = lib.mkForce substituters;
    trusted-public-keys = lib.mkForce trustedPublicKeys;
    fallback = true;
  };

  mkCredentialsSecrets =
    {
      config,
      credentialsFile,
      group,
    }:
    {
      r2-root-access-key-id = {
        rekeyFile = accessKeyFile;
        intermediary = true;
      };

      r2-root-secret-access-key = {
        rekeyFile = secretKeyFile;
        intermediary = true;
      };

      r2-root-credentials = {
        rekeyFile = ../secrets/r2-credentials.age;
        generator = credentialsGenerator {
          accessKeySecret = config.age.secrets.r2-root-access-key-id;
          secretKeySecret = config.age.secrets.r2-root-secret-access-key;
        };
        path = credentialsFile;
        owner = "root";
        inherit group;
        mode = "600";
      };
    };
}
