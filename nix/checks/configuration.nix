{
  flake,
  pkgs,
  system,
  ...
}:

let
  configuration =
    if system == "aarch64-darwin" then
      flake.darwinConfigurations.macbook-pro.config.system.build.toplevel
    else if system == "x86_64-linux" then
      flake.homeConfigurations."k0ch4nx@ubuntu-wsl".activationPackage
    else
      throw "unsupported system: ${system}";
in
pkgs.runCommand "configuration-${system}" { } ''
  ln -s ${configuration} "$out"
''
