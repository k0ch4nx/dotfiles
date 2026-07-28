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
  options.dotfiles.agenixRekey.localStorageDir = lib.mkOption {
    type = lib.types.path;
    description = "Git-tracked directory containing this configuration's rekeyed age files.";
  };

  config.age.rekey = {
    storageMode = "local";
    localStorageDir = config.dotfiles.agenixRekey.localStorageDir;
    masterIdentities = [
      ../../../secrets/master/yubikey-identity.pub
    ];
  }
  // lib.optionalAttrs (hostPubkey != null) {
    inherit hostPubkey;
  };
}
