{
  config,
  flake,
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

  systemd.user.services.agenix.Service.Environment =
    "PATH=${pkgs.age-plugin-yubikey}/bin";

  home = {
    username = "k0ch4nx";
    homeDirectory = "/home/k0ch4nx";
  };
}
