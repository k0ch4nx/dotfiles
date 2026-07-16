{ config, pkgs, ... }:

{
  home.packages = [ pkgs.topgrade ];

  xdg.configFile = {
    "topgrade/commands/common" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/home/k0ch4nx/files/topgrade/commands";
      force = true;
    };
    "topgrade/includes/common" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/home/k0ch4nx/files/topgrade/includes";
      force = true;
    };
  };
}
