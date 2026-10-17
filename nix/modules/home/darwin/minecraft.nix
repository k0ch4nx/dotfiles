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
        icon = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAACABAMAAAAxEHz4AAAAGFBMVEUAAAA4NCrb0LTGvKW8spyAem2uppSakn5SsnMLAAAAAXRSTlMAQObYZgAAAJ5JREFUaIHt1MENgCAMRmFWYAVXcAVXcAVXcH3bhCYNkYjcKO8dSf7v1JASUWdZAlgb0PEmDSMAYYBdGkYApgf8ER3SbwRgesAf0BACMD1gB6S9IbkEEBfwY49oNj4lgLhA64C0o9R9RABTAvp4SX5kB2TA5y8EEAK4pRrxB9QcA4QBWkj3GCAMUCO/xwBhAI/kEsCagCHDY4AwAC3VA6t4zTAMj0OJAAAAAElFTkSuQmCC";
      };
    };
  };
}
