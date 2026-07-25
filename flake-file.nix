# flake-file.nix — module carrier for flake-file generation.
#
# This file is only evaluated when running `nix run .#write-flake` to regenerate
# flake.nix. The generated flake.nix delegates outputs directly to ./outputs.nix,
# so this file is NOT loaded during normal flake evaluation.
#
# We use the `flake` flakeModule (not `default`) because the repository uses
# numtide/blueprint, not hercules-ci/flake-parts. The `flake` module is the
# traditional-flake variant: base + flake-options + write-flake, with no
# flake-parts runtime dependency.
{ inputs }:
inputs.nixpkgs.lib.evalModules {
  specialArgs = {
    inherit inputs;
    self = inputs.self;
  };
  modules = [
    inputs.flake-file.flakeModules.flake
    ./nix/modules/flake-file.nix
  ];
}
