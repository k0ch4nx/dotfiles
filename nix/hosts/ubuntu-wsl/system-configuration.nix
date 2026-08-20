{ flake, pkgs, ... }:

{
  imports = [
    flake.modules.system-manager.docker
    flake.modules.system-manager.nix-cache
    flake.modules.system-manager.pcscd
    flake.modules.system-manager.yubikey
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

  environment.etc."wsl.conf" = {
    replaceExisting = true;
    mode = "0644";
    text = ''
      [boot]
      systemd=true

      [interop]
      appendWindowsPath=false
    '';
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
