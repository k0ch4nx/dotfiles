{
  config,
  hostName,
  lib,
  ...
}:

let
  userName = if config ? home then config.home.username else config.system.primaryUser;
  hostPubkeyPath = ../../../secrets/hosts/${hostName}-${userName}.pub;
  hostPubkey = if builtins.pathExists hostPubkeyPath then builtins.readFile hostPubkeyPath else null;
in
{
  age.rekey = {
    storageMode = "derivation";
    cacheDir = "/var/tmp/agenix-rekey-${userName}";
    masterIdentities = [
      ../../../secrets/master/yubikey-identity.pub
    ];
  }
  // lib.optionalAttrs (hostPubkey != null) {
    inherit hostPubkey;
  };
}
