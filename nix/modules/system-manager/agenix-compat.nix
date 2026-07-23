{ hostName, lib, ... }:

{
  options.networking.hostName = lib.mkOption {
    type = lib.types.str;
    internal = true;
  };

  options.system.activationScripts = builtins.listToAttrs (
    map
      (name: {
        inherit name;
        value = lib.mkOption {
          type = lib.types.raw;
          default = "";
          internal = true;
        };
      })
      [
        "agenix"
        "agenixNewGeneration"
        "agenixInstall"
        "agenixChown"
        "groups"
        "specialfs"
      ]
  );

  config = {
    networking.hostName = hostName;

    systemd.services.agenix-install-secrets = {
      startLimitBurst = 3;
      startLimitIntervalSec = 60;
    };
  };
}
