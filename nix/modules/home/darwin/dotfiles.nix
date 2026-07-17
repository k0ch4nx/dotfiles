{ config, ... }:

{
  xdg.configFile = {
    "borders/bordersrc" = {
      source = ./files/borders/bordersrc;
      executable = true;
    };
    "fzf".source = ./files/fzf;
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "oh-my-posh".source = ./files/oh-my-posh;
    "sketchybar".source = ./files/sketchybar;
    "skhd".source = ./files/skhd;
    "topgrade/topgrade.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/topgrade/topgrade.toml";
      force = true;
    };
    "topgrade/commands/host" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/topgrade/commands";
      force = true;
    };
    "topgrade/includes/host" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/topgrade/includes";
      force = true;
    };
    "wezterm".source = ./files/wezterm;
    "yabai".source = ./files/yabai;
    "ferium/config.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/ferium/config.json";
      force = true;
    };
  };

  home.file = {
    ".config/opencode/opencode.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/opencode/opencode.json";
      force = true;
    };
    ".config/opencode/oh-my-openagent.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/opencode/oh-my-openagent.json";
      force = true;
    };

    ".hushlogin".text = "";
  };
}
