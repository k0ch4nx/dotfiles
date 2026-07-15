{ config, pkgs, ... }:

{
  imports = [
    ../../../../home/k0ch4nx
  ];

  home.packages = with pkgs; [
    fzf
    topgrade
  ];

  xdg.configFile."topgrade/topgrade.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Developer/github.com/k0ch4nx/dotfiles/nix/hosts/ubuntu-wsl/users/k0ch4nx/files/topgrade/topgrade.toml";

  programs = {
    bash.enable = true;
    git.enable = true;
    home-manager.enable = true;
  };
}
