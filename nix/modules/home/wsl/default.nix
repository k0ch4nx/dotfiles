{
  config,
  ...
}:

{
  xdg.configFile = {
    "topgrade/topgrade.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/wsl/files/topgrade/topgrade.toml";
      # Replace the previous directory-level ~/.config/topgrade link.
      force = true;
    };
    "topgrade/commands/host" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/wsl/files/topgrade/commands";
      force = true;
    };
    "topgrade/includes/host" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/wsl/files/topgrade/includes";
      force = true;
    };
  };

  programs.bash.enable = true;
}
