{
  imports = [
    ./borders.nix
    ./dotfiles.nix
    ./minecraft.nix
    ./packages.nix
    ./rift.nix
    ./secrets.nix
    ./shell.nix
    ./vscode.nix
  ];

  rift.signedCopy.enable = true;
}
