{ config, pkgs, ... }:

let
  nvimDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/nvim";
in
{
  home.packages = [ pkgs.neovim ];

  xdg.configFile = {
    "nvim/.luarc.jsonc".source = ./files/nvim/.luarc.jsonc;
    "nvim/after".source = ./files/nvim/after;
    "nvim/init.lua".source = ./files/nvim/init.lua;
    "nvim/lua".source = ./files/nvim/lua;
    "nvim/patches".source = ./files/nvim/patches;
    "nvim/lazy-lock.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${nvimDir}/lazy-lock.json";
      force = true;
    };
    "nvim/mason-lock.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${nvimDir}/mason-lock.json";
      force = true;
    };
  };
}
