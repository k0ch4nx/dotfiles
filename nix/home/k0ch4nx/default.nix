{
  imports = [
    ./shell.nix
    ./packages.nix
    ./dotfiles.nix
    ./secrets.nix
  ];

  home = {
    username = "k0ch4nx";
    homeDirectory = "/Users/k0ch4nx";
    stateVersion = "25.11";
  };
}
