{
  flake,
  ...
}:

{
  imports = [ flake.darwinModules.nix-cache ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "MacBook-Pro";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "k0ch4nx"
    ];
  };

  system = {
    primaryUser = "k0ch4nx";
    stateVersion = 6;
  };

  users.users.k0ch4nx.home = "/Users/k0ch4nx";
}
