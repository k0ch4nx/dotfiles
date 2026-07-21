{ config, ... }:

let
  opencodeDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/opencode";
in
{
  home.file = {
    ".config/opencode/opencode.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${opencodeDir}/opencode.json";
      force = true;
    };
    ".config/opencode/oh-my-openagent.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${opencodeDir}/oh-my-openagent.json";
      force = true;
    };
  };
}
