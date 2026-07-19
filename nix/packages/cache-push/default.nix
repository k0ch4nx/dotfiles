{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "cache-push";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.nix
  ];
  text = builtins.readFile ./cache-push.sh;

  meta = {
    description = "Build, sign, and upload the macbook-pro system closure to Cloudflare R2";
    mainProgram = "cache-push";
    platforms = pkgs.lib.platforms.darwin;
  };
}
