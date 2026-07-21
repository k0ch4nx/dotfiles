{ pkgs, ... }:

{
  home.packages = [
    pkgs.docker-client
    pkgs.stdenv.cc
    pkgs.unzip
  ];
}
