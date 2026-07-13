{
  age.rekey = {
    hostPubkey = builtins.readFile ../../secrets/hosts/MacBook-Pro.pub;
    storageMode = "derivation";
    cacheDir = "/private/var/tmp/agenix-rekey-k0ch4nx";
    masterIdentities = [
      "/Users/k0ch4nx/.config/age/yubikey-identity.txt"
    ];
  };
}
