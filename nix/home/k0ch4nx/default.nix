{ pkgs, ... }:

{
  imports = [
    ../../modules/home/agent-skills.nix
    ../../modules/home/dotfiles.nix
    ./git.nix
    ./neovim.nix
    ./topgrade.nix
  ];

  home = {
    stateVersion = "25.11";

    packages = with pkgs; [
      bat
      eza
      fd
      ripgrep
      uv
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  xdg.enable = true;
}
