let
  accountId = "6118f982b348f7b37129655ee4160301";
  bucket = "nix-cache";
in
{
  inherit accountId bucket;

  url = "s3://${bucket}?endpoint=${accountId}.r2.cloudflarestorage.com&scheme=https&region=auto";

  localPublicKey = "nix-cache-local:GpHBxUjXDkgtfjKeAD/cuGY8pnCjSsZhc8plkslpfFk=";
  ciPublicKey = "nix-cache-ci:8fZtfHt16O6CvXJlPH0H4uqHTs61K5iruLvTAIFIPmU=";

  rootCredentialsFile = {
    darwin = "/var/root/.aws/credentials";
    linux = "/root/.aws/credentials";
  };
}
