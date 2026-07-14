{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  documentation.enable = false;

  system = {
    tools.darwin-uninstaller.enable = false;
    primaryUser = "k0ch4nx";
    stateVersion = 6;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    trusted-users = [
      "root"
      "k0ch4nx"
    ];
  };

  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    wget
  ];

  programs.zsh.enable = true;

  users.users.k0ch4nx.home = "/Users/k0ch4nx";
}
