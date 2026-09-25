{ config, lib, ... }:

let
  restartRift = ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${config.launchd.agents.rift.config.Label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${config.launchd.agents.rift.config.Label}"
    fi
  '';
in

{
  launchd.agents.rift = {
    enable = true;
    config = {
      ProgramArguments = [ "/opt/homebrew/opt/rift/bin/rift" ];
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      Nice = -20;
      ProcessType = "Interactive";
      EnvironmentVariables = {
        NO_COLOR = "1";
        XDG_CONFIG_HOME =
          if config.xdg.enable then config.xdg.configHome else "${config.home.homeDirectory}/.config";
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/rift-out.log";
      StandardErrorPath = "/tmp/rift-err.log";
    };
  };

  xdg.configFile."rift/config.toml" = lib.mkIf config.xdg.enable {
    source = ./files/rift/config.toml;
    onChange = restartRift;
  };
}
