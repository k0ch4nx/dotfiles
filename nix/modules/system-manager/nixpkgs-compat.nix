{ lib, ... }:

{
  options.services.displayManager.hiddenUsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    internal = true;
  };
}
