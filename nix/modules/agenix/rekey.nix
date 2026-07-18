{
  config,
  hostName,
  ...
}:

let
  userName = if config ? home then config.home.username else config.system.primaryUser;
in
{
  age.rekey = {
    hostPubkey = builtins.readFile ../../../secrets/hosts/${hostName}-${userName}.pub;
    storageMode = "derivation";
    cacheDir = "/var/tmp/agenix-rekey-${userName}";
    masterIdentities = [
      ../../../secrets/master/yubikey-identity.pub
    ];
  };
}
