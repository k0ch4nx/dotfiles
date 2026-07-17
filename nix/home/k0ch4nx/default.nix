{ pkgs, ... }:

{
  imports = [
    ../../modules/home/agent-skills.nix
    ../../modules/home/dotfiles.nix
    ./git.nix
    ./neovim.nix
    ./ssh.nix
    ./topgrade.nix
  ];

  home = {
    stateVersion = "25.11";

    packages = with pkgs; [
      age-plugin-yubikey
      aria2
      asciinema
      bat
      bacon
      bazelisk
      bottom
      bun
      cloudflared
      cmake
      commitizen
      dotnet-sdk_10
      eza
      fd
      fastfetch
      ffmpeg-full
      gh
      git-cliff
      gitlogue
      google-cloud-sdk
      gradle
      haiti
      hashcat
      hyperfine
      imagemagick
      john
      lazygit
      mpv
      nixfmt
      nodejs_latest
      oh-my-posh
      onefetch
      opencode
      openssh
      progress
      python314
      python3Packages.huggingface-hub
      python3Packages.lizard
      rage
      ripgrep
      rustup
      temurin-bin-25
      terraform
      tokei
      tree-sitter
      uv
      yubikey-manager
      zig
      zsh-fzf-tab
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
}
