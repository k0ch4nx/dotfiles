{ pkgs, ... }:

{
  home.packages = [
    pkgs.docker
    pkgs.stdenv.cc
    pkgs.unzip
  ];
}
