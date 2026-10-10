{ inputs }:
inputs.nixpkgs.lib.evalModules {
  specialArgs = {
    inherit inputs;
    inherit (inputs) self;
  };
  modules = [
    inputs.flake-file.flakeModules.flake
    ./nix/modules/flake-file.nix
  ];
}
