{ inputs, ... }:

{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/services.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
    ../../modules/rekey.nix
  ];

  networking.hostName = "MacBook-Pro";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.k0ch4nx = import ../../home/k0ch4nx;
  };
}
