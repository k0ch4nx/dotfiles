{ config, lib, ... }:

let
  cfg = config.dotfiles;
in
{
  options.dotfiles = {
    ghqRoot = lib.mkOption {
      type = lib.types.str;
      description = "Root directory managed by ghq.";
    };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "github.com";
      description = "Remote host directory used by ghq.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "k0ch4nx";
      description = "Repository owner directory used by ghq.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      default = "dotfiles";
      description = "Dotfiles repository directory name.";
    };

    path = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Absolute path to the dotfiles repository.";
    };
  };

  config = {
    dotfiles.path = "${cfg.ghqRoot}/${cfg.remote}/${cfg.user}/${cfg.repo}";

    home.sessionVariables.DOTFILES_DIR = cfg.path;

    xdg.configFile."dotfiles/path".text = "${cfg.path}\n";
  };
}
