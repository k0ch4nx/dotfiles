{
  flake,
  hostName,
  inputs,
  ...
}:

{
  imports = [
    flake.darwinModules.base
    flake.darwinModules.homebrew
    flake.darwinModules.defaults
    flake.darwinModules.services
    flake.darwinModules.nix-cache
    flake.darwinModules.nix-gc
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
    flake.modules.agenix.rekey
  ];

  home-manager.extraSpecialArgs = { inherit hostName; };

  networking.hostName = "MacBook-Pro";
}
