{
  config,
  hostName,
  lib,
  ...
}:

let
  userName = if config ? home then config.home.username else config.system.primaryUser;
in
{
  config.age.rekey = import ./rekey-lib.nix { inherit lib hostName userName; };
}
