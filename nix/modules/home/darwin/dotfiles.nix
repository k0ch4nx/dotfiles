{ config, ... }:

{
  xdg.configFile = {
    "borders/bordersrc" = {
      source = ./files/borders/bordersrc;
      executable = true;
    };
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "sketchybar".source = ./files/sketchybar;
    "skhd".source = ./files/skhd;
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
