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
