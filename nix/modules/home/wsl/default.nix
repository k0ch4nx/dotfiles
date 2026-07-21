{ pkgs, ... }:

{
  home.packages = [ pkgs.stdenv.cc ];
}
