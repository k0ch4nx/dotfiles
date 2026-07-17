{ pkgs }:

let
  mkCommand = import ./mk-command.nix { inherit pkgs; };

  commonPackages = {
    nix-update = mkCommand {
      name = "nix-update";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/nix-update.sh;
    };

    dotfiles-check = mkCommand {
      name = "dotfiles-check";
      runtimeInputs = [
        pkgs.nix
        pkgs.shellcheck
      ];
      script = ./scripts/dotfiles-check.sh;
    };

    neovim-lazy = mkCommand {
      name = "neovim-lazy";
      runtimeInputs = [ pkgs.neovim ];
      script = ./scripts/neovim-lazy.sh;
    };

    neovim-treesitter = mkCommand {
      name = "neovim-treesitter";
      runtimeInputs = [ pkgs.neovim ];
      script = ./scripts/neovim-treesitter.sh;
    };

    neovim-mason = mkCommand {
      name = "neovim-mason";
      runtimeInputs = [ pkgs.neovim ];
      script = ./scripts/neovim-mason.sh;
    };

    neovim-codediff = mkCommand {
      name = "neovim-codediff";
      runtimeInputs = [ pkgs.neovim ];
      script = ./scripts/neovim-codediff.sh;
    };
  };

  darwinPackages = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
    darwin-ci-secrets = mkCommand {
      name = "darwin-ci-secrets";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/darwin-ci-secrets.sh;
    };

    darwin-build = mkCommand {
      name = "darwin-build";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/darwin-build.sh;
    };

    agenix-rekey = mkCommand {
      name = "agenix-rekey";
      runtimeInputs = [
        pkgs.age-plugin-yubikey
        pkgs.nix
        pkgs.rage
      ];
      script = ./scripts/agenix-rekey.sh;
    };

    darwin-switch = mkCommand {
      name = "darwin-switch";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/darwin-switch.sh;
    };

    homebrew-clean-build-dependencies = mkCommand {
      name = "homebrew-clean-build-dependencies";
      script = ./scripts/homebrew-clean-build-dependencies.sh;
    };

    github-cli-extensions = mkCommand {
      name = "github-cli-extensions";
      runtimeInputs = [ pkgs.gh ];
      script = ./scripts/github-cli-extensions.sh;
    };

    rustup-update = mkCommand {
      name = "rustup-update";
      runtimeInputs = [ pkgs.rustup ];
      script = ./scripts/rustup-update.sh;
    };

    ferium-upgrade = mkCommand {
      name = "ferium-upgrade";
      runtimeInputs = [ pkgs.ferium ];
      script = ./scripts/ferium-upgrade.sh;
    };

    macos-update = mkCommand {
      name = "macos-update";
      script = ./scripts/macos-update.sh;
    };
  };

  linuxPackages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
    home-manager-build = mkCommand {
      name = "home-manager-build";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/home-manager-build.sh;
    };

    home-manager-switch = mkCommand {
      name = "home-manager-switch";
      runtimeInputs = [ pkgs.nix ];
      script = ./scripts/home-manager-switch.sh;
    };

    apt-upgrade = mkCommand {
      name = "apt-upgrade";
      script = ./scripts/apt-upgrade.sh;
    };
  };
in
commonPackages // darwinPackages // linuxPackages
