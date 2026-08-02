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
    inputs.agenix-rekey.darwinModules.default
    flake.modules.agenix.rekey
  ];

  nix.settings = cache.mkNixSettings lib;

  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
    AWS_SHARED_CREDENTIALS_FILE = system.credentialsFile;
  };
}
