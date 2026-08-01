{
  config,
  hostName,
  lib,
  ...
}:

{
  config.age.rekey = import ../agenix/rekey-lib.nix {
    inherit lib hostName;
    userName = "k0ch4nx";
  };
}
