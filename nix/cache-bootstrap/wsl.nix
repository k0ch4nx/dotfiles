{ flake, ... }:

{
  imports = [ flake.modules.system-manager.nix-cache ];

  age.rekey.localStorageDir = import ../modules/agenix/rekey-dirs.nix {
    hostName = "ubuntu-wsl";
    scope = "system";
  };

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
