{
  config,
  flake,
  hostName,
  lib,
  ...
}:

let
  primaryUser = lib.escapeShellArg config.system.primaryUser;

  disabledHotkey = lib.escapeShellArg (
    lib.generators.toPlist { escape = true; } {
      enabled = false;
      value.parameters = [
        32
        49
        262144
      ];
      value.type = "standard";
    }
  );
in
{
  imports = [
    flake.darwinModules.base
    flake.darwinModules.homebrew
    flake.darwinModules.defaults
    flake.darwinModules.nix-cache
  ];

  home-manager.extraSpecialArgs = { inherit hostName; };

  networking.hostName = "MacBook-Pro";

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/pmset -a displaysleep 10
    /usr/bin/pmset -b lessbright 0
    /usr/bin/pmset -c sleep 0

    /bin/launchctl asuser "$(/usr/bin/id -u ${primaryUser})" \
      /usr/bin/sudo -u ${primaryUser} --set-home \
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
      ${disabledHotkey}
  '';
}
