{ pkgs, ... }:

{
  imports = [
    ./vscode.nix
  ];

  home.packages = [
    pkgs.stdenv.cc
    pkgs.unzip
    pkgs.mcat
    pkgs.sheets
    pkgs.snitch
    pkgs.superseedr
  ];

  home.sessionVariables.SSH_ASKPASS_REQUIRE = "never";
}
