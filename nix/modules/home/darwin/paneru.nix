{
  config,
  inputs,
  lib,
  ...
}:

let
  restartPaneru = ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${config.launchd.agents.paneru.config.Label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${config.launchd.agents.paneru.config.Label}"
    fi
  '';
in

{
  imports = [ inputs.paneru.homeModules.paneru ];

  services.paneru = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./files/paneru/paneru.toml);
  };

  xdg.configFile."paneru/paneru.toml" =
    lib.mkIf (config.services.paneru.enable && config.xdg.enable)
      {
        onChange = restartPaneru;
      };
}
