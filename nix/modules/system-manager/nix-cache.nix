{
  flake,
  inputs,
  lib,
  ...
}:

let
  cache = import ../../r2-cache.nix;
  system = cache.systems.x86_64-linux;
in
{
  imports = [
    flake.modules.system-manager.agenix-compat
    flake.modules.system-manager.agenix-rekey
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  config = {
    users.groups.keys = { };

    nix.settings = cache.mkNixSettings lib;

    environment.etc."systemd/system/nix-daemon.service.d/r2-cache.conf" = {
      mode = "0644";
      text = ''
        [Service]
        Environment="AWS_SHARED_CREDENTIALS_FILE=${system.credentialsFile}"
      '';
    };
  };
}
