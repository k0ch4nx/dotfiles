{ flake, ... }:

{
  imports = [ flake.modules.system-manager.nix-cache ];

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
}
