{ config, ... }:

let
  packMcVersion =
    name:
    (builtins.fromTOML (builtins.readFile ../../../../minecraft/${name}/pack.toml)).versions.minecraft;
in
{
  minecraft = {
    baseDir = "${config.home.homeDirectory}/Library/Application Support/minecraft";

    profiles = {
      "fabric-26.3" = {
        mcVersion = packMcVersion "fabric-26.3";
        loader = "fabric";
      };
    };
  };
}
