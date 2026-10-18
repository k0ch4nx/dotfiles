{
  flake,
  hostName,
  lib,
  ...
}:

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
    pmset -a displaysleep 10
    pmset -c disksleep 0
    pmset -b disksleep 0
  '';
}
