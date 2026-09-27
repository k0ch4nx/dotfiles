{ config, ... }:

{
  minecraft = {
    baseDir = "${config.home.homeDirectory}/Library/Application Support/minecraft";

    profiles = {
      latest = {
        mcVersion = "26.3";
        loader = "vanilla";
      };
      snapshot = {
        mcVersion = "26.4-snapshot-1";
        loader = "vanilla";
      };
      "fabric-26.3" = {
        mcVersion = "26.3";
        loaderVersion = "0.19.5";
      };
    };
  };
}
