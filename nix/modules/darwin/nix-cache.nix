{
  config,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  credentialsFile = cache.rootCredentialsFile.darwin;
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  resolvedDotfilesDir =
    if dotfilesDir != "" then
      dotfilesDir
    else
      "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles";
in
{
  config = {
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

    age = {
      identityPaths = [
        "${resolvedDotfilesDir}/secrets/hosts/macbook-pro-k0ch4nx-key.txt"
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
          group = "wheel";
          mode = "600";
        };
      };
    };

    nix.settings = {
      substituters = lib.mkForce cache.substituters;
      trusted-public-keys = lib.mkForce cache.trustedPublicKeys;
      fallback = true;
    };

    launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
      AWS_SHARED_CREDENTIALS_FILE = credentialsFile;
    };
  };
}
