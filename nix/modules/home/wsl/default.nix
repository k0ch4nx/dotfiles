{ pkgs, ... }:

{
  home.packages = [
    pkgs.stdenv.cc
    pkgs.unzip
  ];
}
