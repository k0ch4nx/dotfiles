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

  age.rekey.localStorageDir = import ../../modules/agenix/rekey-dirs.nix {
    hostName = "macbook-pro";
    scope = "system";
  };

  home-manager.extraSpecialArgs = { inherit hostName; };

  networking.hostName = "MacBook-Pro";
}
