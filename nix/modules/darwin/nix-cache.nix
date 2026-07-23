{
  config,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  host = cache.hosts.macbook-pro;
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  resolvedDotfilesDir =
    if dotfilesDir != "" then
      dotfilesDir
    else
      "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles";
in
{
  config = lib.mkMerge [
    {
      nix.settings = cache.mkNixSettings lib;

      launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
        AWS_SHARED_CREDENTIALS_FILE = host.credentialsFile;
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
          credentialsFile = host.credentialsFile;
          group = host.credentialsGroup;
        };
      };
    })
  ];
}
