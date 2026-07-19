{
  config,
  hostName,
  lib,
  ...
}:

let
  userName = if config ? home then config.home.username else config.system.primaryUser;
  hostPubkeyPath = ../../../secrets/hosts/${hostName}-${userName}.pub;
  environmentHostPubkey = builtins.getEnv "AGENIX_REKEY_HOST_PUBKEY";
  hostPubkey =
    if environmentHostPubkey != "" then
      environmentHostPubkey
    else if builtins.pathExists hostPubkeyPath then
      builtins.readFile hostPubkeyPath
    else
      null;
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
