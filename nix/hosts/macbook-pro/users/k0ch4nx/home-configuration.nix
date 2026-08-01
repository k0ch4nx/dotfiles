{ config, flake, ... }:

{
  imports = [
    ../../../../home/k0ch4nx
    flake.homeModules.darwin
  ];

  age.rekey.localStorageDir = import ../../../../modules/agenix/rekey-dirs.nix {
    hostName = "macbook-pro";
    scope = "home";
  };

  home = {
    username = "k0ch4nx";
    homeDirectory = "/Users/k0ch4nx";
  };

  dotfiles.ghqRoot = "${config.home.homeDirectory}/Developer";
}
