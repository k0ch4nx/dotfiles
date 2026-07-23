{ pkgs, ... }:

let
  cache = import ../../r2-cache.nix;
in
pkgs.writeShellApplication {
  name = "cache-push";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.nix
  ];
  runtimeEnv = {
    DEFAULT_CLOUDFLARE_ACCOUNT_ID = cache.accountId;
    DEFAULT_R2_CACHE_BUCKET = cache.bucket;
  };
  text = builtins.readFile ./cache-push.sh;

  meta = {
    description = "Build, sign, and upload the local system closure to Cloudflare R2";
    mainProgram = "cache-push";
    platforms = pkgs.lib.platforms.unix;
  };
}
