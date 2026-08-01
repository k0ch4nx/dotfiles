{
  config,
  lib,
  pkgs,
  ...
}:

let
  extensions = import ../vscode-extensions.nix { inherit pkgs; };

  extensionLinks = lib.mkMerge (
    map (ext: {
      ".vscode-server/extensions/${ext.vscodeExtPublisher}.${ext.vscodeExtName}-${ext.version}" = {
        source = "${ext}/share/vscode/extensions/${ext.vscodeExtPublisher}.${ext.vscodeExtName}-${ext.version}";
      };
    }) extensions
  );
in
{
  home.file = extensionLinks // {
    ".vscode-server/data/Machine/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/home/k0ch4nx/files/vscode/settings.json";
      force = true;
    };
  };
}
