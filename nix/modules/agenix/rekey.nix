{ config, ... }:

let
  userName = if config ? home then config.home.username else config.system.primaryUser;
  homeDirectory =
    if config ? home then config.home.homeDirectory else config.users.users.${userName}.home;
in
{
  age.rekey = {
    hostPubkey = builtins.readFile ../../../secrets/hosts/macbook-pro.pub;
    storageMode = "derivation";
    cacheDir = "/private/var/tmp/agenix-rekey-${userName}";
    masterIdentities = [
      "${homeDirectory}/.config/age/yubikey-identity.txt"
    ];
  };
}
