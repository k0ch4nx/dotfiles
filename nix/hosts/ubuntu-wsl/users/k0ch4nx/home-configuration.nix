{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../home/k0ch4nx
    flake.homeModules.wsl
  ];

  _module.args.hostName = "ubuntu-wsl";

  dotfiles.ghqRoot = "${config.home.homeDirectory}/src";

  systemd.user.services.agenix = {
    Install.WantedBy = lib.mkForce [ ];

    Service.Environment =
      "PATH=${pkgs.age-plugin-yubikey}/bin";
  };

  home.activation.activateAgenixInteractively =
    lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      PATH=${pkgs.age-plugin-yubikey}/bin:$PATH \
        ${builtins.head config.systemd.user.services.agenix.Service.ExecStart}

      systemctl --user reset-failed agenix.service || true
    '';

  home = {
    username = "k0ch4nx";
    homeDirectory = "/home/k0ch4nx";
  };
}
