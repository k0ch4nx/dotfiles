{ flake, ... }:

{
  imports = [ flake.modules.system-manager.docker ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
