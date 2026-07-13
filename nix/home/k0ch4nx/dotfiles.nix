{ config, ... }:

{
  xdg.configFile = {
    "borders/bordersrc" = {
      source = ./files/borders/bordersrc;
      executable = true;
    };
    "fzf".source = ./files/fzf;
    "git".source = ./files/git;
    "lazygit".source = ./files/lazygit;
    "nvim/.luarc.jsonc".source = ./files/nvim/.luarc.jsonc;
    "nvim/after".source = ./files/nvim/after;
    "nvim/init.lua".source = ./files/nvim/init.lua;
    "nvim/lua".source = ./files/nvim/lua;
    "nvim/patches".source = ./files/nvim/patches;
    "nvim/lazy-lock.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/nix/home/k0ch4nx/files/nvim/lazy-lock.json";
      force = true;
    };
    "nvim/mason-lock.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/nix/home/k0ch4nx/files/nvim/mason-lock.json";
      force = true;
    };
    "oh-my-posh".source = ./files/oh-my-posh;
    "sketchybar".source = ./files/sketchybar;
    "skhd".source = ./files/skhd;
    "topgrade".source = ./files/topgrade;
    "wezterm".source = ./files/wezterm;
    "yabai".source = ./files/yabai;
    "ferium/config.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/nix/home/k0ch4nx/files/ferium/config.json";
      force = true;
    };
  };

  home.file = {
    ".config/opencode/opencode.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/nix/home/k0ch4nx/files/opencode/opencode.json";
      force = true;
    };
    ".config/opencode/oh-my-openagent.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/nix/home/k0ch4nx/files/opencode/oh-my-openagent.json";
      force = true;
    };

    ".hushlogin".text = "";

    ".ssh/allowed_signers".source = ./files/ssh/allowed_signers;
    ".ssh/authorized_keys".source = ./files/ssh/authorized_keys;
    ".ssh/config".source = ./files/ssh/config;
    ".ssh/id_ed25519.pub".source = ./files/ssh/id_ed25519.pub;
    ".ssh/id_ed25519_gh_work.pub".source = ./files/ssh/id_ed25519_gh_work.pub;
    ".ssh/id_ed25519_sk.pub".source = ./files/ssh/id_ed25519_sk.pub;
    ".ssh/id_ed25519_sk_gh_auth_pers.pub".source = ./files/ssh/id_ed25519_sk_gh_auth_pers.pub;
    ".ssh/id_ed25519_sk_gh_sign_pers.pub".source = ./files/ssh/id_ed25519_sk_gh_sign_pers.pub;
  };
}
