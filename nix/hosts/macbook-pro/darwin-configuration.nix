{
  flake,
  hostName,
  ...
}:

{
  imports = [
    flake.darwinModules.base
    flake.darwinModules.homebrew
    flake.darwinModules.defaults
    flake.darwinModules.services
    flake.darwinModules.nix-cache
  ];

  home-manager.extraSpecialArgs = { inherit hostName; };

  networking.hostName = "MacBook-Pro";
}
