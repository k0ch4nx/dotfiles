{
  config,
  inputs,
  lib,
  ...
}:

{
  disabledModules = [
    "${inputs.system-manager}/nix/modules/upstream/nixpkgs/nix.nix"
  ];

  options.services.displayManager.hiddenUsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    internal = true;
  };

  config = lib.mkIf config.nix.enable {
    environment.etc."nix/nix.conf".replaceExisting = true;
  };
}
