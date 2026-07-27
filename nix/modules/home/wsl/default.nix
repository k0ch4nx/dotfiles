{ pkgs, ... }:

{
  home.packages = [
    pkgs.stdenv.cc
    pkgs.unzip
  ];

  home.sessionVariables.SSH_ASKPASS_REQUIRE = "never";
}
