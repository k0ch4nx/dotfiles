{ pkgs, ... }:

{
  imports = [
    ../../../../modules/home/agent-skills.nix
  ];

  home = {
    stateVersion = "25.11";

    packages = with pkgs; [
      bat
      eza
      fd
      fzf
      neovim
      ripgrep
      uv
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs = {
    bash.enable = true;
    git.enable = true;
    home-manager.enable = true;
  };

  xdg.enable = true;
}
