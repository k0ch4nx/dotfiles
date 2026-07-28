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
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
    flake.modules.agenix.rekey
  ];

  dotfiles.agenixRekey.localStorageDir = ../../.. + "/secrets/rekeyed/macbook-pro/system";

  home-manager.extraSpecialArgs = { inherit hostName; };

  networking.hostName = "MacBook-Pro";
}
