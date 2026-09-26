{ config, lib, pkgs, ... }:

let
  restartRift = ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${config.launchd.agents.rift.config.Label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${config.launchd.agents.rift.config.Label}"
    fi
  '';
in

{
  home.packages = [ pkgs.rift-wm ];

  launchd.agents.rift = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.rift-wm}/bin/rift" ];
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      Nice = -20;
      ProcessType = "Interactive";
      EnvironmentVariables = {
        XDG_CONFIG_HOME =
          if config.xdg.enable then config.xdg.configHome else "${config.home.homeDirectory}/.config";
      };
      RunAtLoad = true;
    };
  };

  xdg.configFile."rift/config.toml" = lib.mkIf config.xdg.enable {
    source = ./files/rift/config.toml;
    onChange = restartRift;
  };
}
