{ config, lib, ... }:

let
  restartLaunchAgent = label: ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${label}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${label}"
    fi
  '';
in

{
  xdg.configFile = {
    "borders/bordersrc" = {
      source = ./files/borders/bordersrc;
      executable = true;
    };
    "git/ignore".text = ''
      .DS_Store
    '';
    "lazygit".source = ./files/lazygit;
    "sketchybar".source = ./files/sketchybar;
    "skhd".source = ./files/skhd;
    "wezterm".source = ./files/wezterm;
    "yabai" = {
      source = ./files/yabai;
      onChange = restartLaunchAgent "org.nixos.yabai";
    };
    "ferium/config.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/nix/modules/home/darwin/files/ferium/config.json";
      force = true;
    };
  };

  home.activation.skhdService = lib.hm.dag.entryAfter [ "onFilesChange" ] ''
    skhd="/Applications/skhd.app/Contents/MacOS/skhd"
    legacyServiceLabel="org.nixos.skhd"
    legacyServicePlist="${config.home.homeDirectory}/Library/LaunchAgents/$legacyServiceLabel.plist"

    if [ -x "$skhd" ]; then
      userId="$(/usr/bin/id -u)"

      if /bin/launchctl print "gui/$userId/$legacyServiceLabel" >/dev/null 2>&1 || [ -f "$legacyServicePlist" ]; then
        $DRY_RUN_CMD /bin/launchctl bootout "gui/$userId/$legacyServiceLabel" >/dev/null 2>&1 || true
        $DRY_RUN_CMD /bin/rm -f "$legacyServicePlist"
      fi

      $DRY_RUN_CMD "$skhd" --install-service
    fi
  '';

  home.file.".hushlogin".text = "";
}
