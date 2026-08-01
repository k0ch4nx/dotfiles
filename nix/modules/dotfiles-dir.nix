{ fallback }:

let
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
in
if dotfilesDir != "" then dotfilesDir else fallback
