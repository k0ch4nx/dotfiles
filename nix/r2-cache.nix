let
  accountId = "6118f982b348f7b37129655ee4160301";
  bucket = "nix-cache";
  url = "s3://${bucket}?endpoint=${accountId}.r2.cloudflarestorage.com&scheme=https&region=auto&priority=30";
  localPublicKey = "nix-cache-local:GpHBxUjXDkgtfjKeAD/cuGY8pnCjSsZhc8plkslpfFk=";
  ciPublicKey = "nix-cache-ci:8fZtfHt16O6CvXJlPH0H4uqHTs61K5iruLvTAIFIPmU=";
  substituters = [
    "https://cache.nixos.org/?priority=10"
    "https://nix-community.cachix.org?priority=20"
    url
  ];
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    localPublicKey
    ciPublicKey
  ];
in
{
  inherit
    accountId
    bucket
    ciPublicKey
    localPublicKey
    substituters
    trustedPublicKeys
    url
    ;

  settings = {
    inherit substituters;
    trusted-public-keys = trustedPublicKeys;
    fallback = true;
  };

  rootCredentialsFile = {
    darwin = "/var/root/.aws/credentials";
    linux = "/root/.aws/credentials";
  };

  credentialsGenerator =
    {
      accessKeyFile,
      secretKeyFile,
    }:
    {
      tags = [ "r2" ];

      script =
        {
          decrypt,
          lib,
          ...
        }:
        ''
          accessKeyId="$(${decrypt} ${lib.escapeShellArg (builtins.toString accessKeyFile)})"
          secretAccessKey="$(${decrypt} ${lib.escapeShellArg (builtins.toString secretKeyFile)})"

          [ -n "$accessKeyId" ]
          [ -n "$secretAccessKey" ]
          [ "''${#accessKeyId}" -eq 32 ]
          [ "''${#secretAccessKey}" -eq 64 ]

          printf \
            '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
            "$accessKeyId" \
            "$secretAccessKey"
        '';
    };
}
