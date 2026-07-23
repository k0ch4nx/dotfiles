{ flake, pkgs, ... }:

{
  imports = [
    flake.modules.system-manager.docker
    flake.modules.system-manager.nix-cache
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  nix = {
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "k0ch4nx"
      ];
    };
  };

  users = {
    groups.k0ch4nx = { };

    users.k0ch4nx = {
      isNormalUser = true;
      group = "k0ch4nx";
      shell = pkgs.zsh;
      ignoreShellProgramCheck = true;
    };
  };
}
