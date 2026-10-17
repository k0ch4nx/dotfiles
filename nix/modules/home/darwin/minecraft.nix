{ config, ... }:

let
  packMcVersion =
    name:
    (builtins.fromTOML (builtins.readFile ../../../../minecraft/${name}/pack.toml)).versions.minecraft;

  baseDir = "${config.home.homeDirectory}/Library/Application Support/minecraft";
in
{
  minecraft = {
    inherit baseDir;

    profiles = {
      latest = {
        type = "latest-release";
      };
      snapshot = {
        type = "latest-snapshot";
      };
      "fabric-26.3" = {
        mcVersion = packMcVersion "fabric-26.3";
        loader = "fabric";
      };
    };
  };
}
