{ config, pkgs, ... }:

let
  vscodeDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/vscode";
  vscodePackage = pkgs.vscode.overrideAttrs (old: {
    postPatch =
      builtins.replaceStrings
        [ "Contents/Resources/app/node_modules/@vscode/ripgrep-universal" ]
        [ "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal" ]
        old.postPatch;
  });
  extensions = import ../vscode-extensions.nix { inherit pkgs; };
in
{
  programs.vscode = {
    enable = true;
    package = vscodePackage;

    profiles.default = {
      inherit extensions;

      userSettings = config.lib.file.mkOutOfStoreSymlink "${vscodeDir}/settings.json";
    };
  };

  home.file."${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json".force =
    true;
}
