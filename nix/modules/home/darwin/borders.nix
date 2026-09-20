{ config, pkgs, ... }:

let
  restartLaunchAgent = label: ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${label}"
    fi
  '';
in

{
  xdg.configFile."borders/bordersrc" = {
    source = ./files/borders/bordersrc;
    executable = true;
    onChange = restartLaunchAgent config.launchd.agents.jankyborders.config.Label;
  };

  launchd.agents.jankyborders = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "${config.home.homeDirectory}/.config/borders/bordersrc"
      ];
      EnvironmentVariables.PATH = "${pkgs.jankyborders}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      KeepAlive = {
        Crashed = true;
      };
      RunAtLoad = true;
    };
  };
}
