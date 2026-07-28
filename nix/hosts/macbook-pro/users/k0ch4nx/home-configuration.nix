{ config, flake, ... }:

{
  imports = [
    ../../../../home/k0ch4nx
    flake.homeModules.darwin
  ];

  dotfiles.agenixRekey.localStorageDir = ../../../../.. + "/secrets/rekeyed/macbook-pro/home";

  home = {
    username = "k0ch4nx";
    homeDirectory = "/Users/k0ch4nx";
  };

  dotfiles.ghqRoot = "${config.home.homeDirectory}/Developer";
}
