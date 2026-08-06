{
  inputs,
  pkgs,
  ...
}:

let
  cache = import ../../r2-cache.nix;

  ageWithYubiKey = pkgs.writeShellApplication {
    name = "age";

    runtimeInputs = [
      pkgs.age-plugin-yubikey
    ];

    text = ''
      exec ${pkgs.age}/bin/age "$@"
    '';
  };
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  age = {
    identityPaths = [
      ../../../secrets/yubikey-identity.txt
    ];

    package = ageWithYubiKey;
  };

  home.sessionVariables = {
    CLOUDFLARE_ACCOUNT_ID = cache.accountId;
    R2_CACHE_BUCKET = cache.bucket;
  };
}
