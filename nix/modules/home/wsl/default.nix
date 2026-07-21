{ pkgs, ... }:

{
  home.packages = [ pkgs.stdenv.cc ];

  programs.bash.enable = true;
}
