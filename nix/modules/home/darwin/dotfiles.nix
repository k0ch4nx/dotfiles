{ ... }:

{
  xdg.configFile = {
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "sketchybar".source = ./files/sketchybar;
    "wezterm".source = ./files/wezterm;
  };

  home.file.".hushlogin".text = "";
}
