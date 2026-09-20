{ config, ... }:

{
  xdg.configFile = {
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "sketchybar".source = ./files/sketchybar;
    "wezterm".source = ./files/wezterm;
    "ferium/config.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/ferium/config.json";
      force = true;
    };
  };

  home.file.".hushlogin".text = "";
}
