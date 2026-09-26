{
  config,
  lib,
  pkgs,
  ...
}:

let
  restartBorders = ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${config.launchd.agents.borders.config.Label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${config.launchd.agents.borders.config.Label}"
    fi
  '';
in

{
  home.packages = [ pkgs.jankyborders ];

  launchd.agents.borders = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.jankyborders}/bin/borders" ];
      EnvironmentVariables.PATH = "${pkgs.jankyborders}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
    };
  };

  xdg.configFile."borders/bordersrc" = lib.mkIf config.xdg.enable {
    source = ./files/borders/bordersrc;
    executable = true;
    onChange = restartBorders;
  };
}
