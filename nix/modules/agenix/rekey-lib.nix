{
  lib,
  hostName,
  userName,
}:

let
  hostPubkeyPath = ../../../secrets/hosts/${hostName}-${userName}.pub;
  hostPubkey = if builtins.pathExists hostPubkeyPath then builtins.readFile hostPubkeyPath else null;
in
{
  storageMode = "local";
  masterIdentities = [
    ../../../secrets/master/yubikey-identity.pub
  ];
}
// lib.optionalAttrs (hostPubkey != null) {
  inherit hostPubkey;
}
