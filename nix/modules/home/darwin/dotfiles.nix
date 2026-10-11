{ ... }:

{
  xdg.configFile = {
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "wezterm".source = ./files/wezterm;
  };

  home.file.".hushlogin".text = "";
}
