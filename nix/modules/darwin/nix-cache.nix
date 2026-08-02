{
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  system = cache.systems.aarch64-darwin;
in
{
  imports = [
    inputs.agenix.darwinModules.default
  ];

  nix.settings = cache.mkNixSettings lib;

  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
    AWS_SHARED_CREDENTIALS_FILE = system.credentialsFile;
  };
}
