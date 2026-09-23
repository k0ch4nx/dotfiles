{ ... }:

let
  restartApp = appName: ''
    if /usr/bin/pgrep -x "${appName}" >/dev/null 2>&1; then
      /usr/bin/pkill -x "${appName}"
      /bin/sleep 1
      /usr/bin/open -a "${appName}"
    fi
  '';
in

{
  home.file.".hammerspoon/init.lua" = {
    source = ./files/hammerspoon/init.lua;
    onChange = restartApp "Hammerspoon";
  };
}
