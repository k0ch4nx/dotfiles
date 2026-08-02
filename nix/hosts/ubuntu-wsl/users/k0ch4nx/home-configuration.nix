{
  config,
  flake,
  ...
}:

{
  imports = [
    ../../../../home/k0ch4nx
    flake.homeModules.wsl
  ];

  _module.args.hostName = "ubuntu-wsl";

  dotfiles.ghqRoot = "${config.home.homeDirectory}/src";

  home = {
    username = "k0ch4nx";
    homeDirectory = "/home/k0ch4nx";
  };
}
