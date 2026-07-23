{
  flake,
  inputs,
  ...
}:

{
  imports = [
    flake.darwinModules.nix-cache
    inputs.agenix.darwinModules.default
    inputs.agenix-rekey.darwinModules.default
    flake.modules.agenix.rekey
  ];

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
