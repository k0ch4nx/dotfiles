{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../home/k0ch4nx
  ];

  home.packages = with pkgs; [
    fzf
  ];

  dotfiles.ghqRoot = "${config.home.homeDirectory}/src";

  xdg.configFile = {
    "topgrade/topgrade.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/hosts/ubuntu-wsl/users/k0ch4nx/files/topgrade/topgrade.toml";
      # Replace the previous directory-level ~/.config/topgrade link.
      force = true;
    };
    "topgrade/commands/host".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/hosts/ubuntu-wsl/users/k0ch4nx/files/topgrade/commands";
    "topgrade/includes/host".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/hosts/ubuntu-wsl/users/k0ch4nx/files/topgrade/includes";
  };

  programs = {
    bash.enable = true;
    home-manager.enable = true;
  };
}
