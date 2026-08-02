{ config, flake, ... }:

{
  imports = [
    ../../../../home/k0ch4nx
    flake.homeModules.darwin
  ];

  home = {
    username = "k0ch4nx";
    homeDirectory = "/Users/k0ch4nx";
  };

  dotfiles.ghqRoot = "${config.home.homeDirectory}/Developer";
}
