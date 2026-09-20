{ config, lib, ... }:

let
  inherit (config.users.users.k0ch4nx) home;

  symbolichotkeys = {
    "79" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          35
          524288
        ];
      };
    };
    "81" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          45
          524288
        ];
      };
    };
    "118" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          18
          524288
        ];
      };
    };
    "119" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          19
          524288
        ];
      };
    };
    "120" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          20
          524288
        ];
      };
    };
    "121" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          21
          524288
        ];
      };
    };
    "122" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          23
          524288
        ];
      };
    };
    "123" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          22
          524288
        ];
      };
    };
    "124" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          26
          524288
        ];
      };
    };
    "125" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          28
          524288
        ];
      };
    };
    "126" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          25
          524288
        ];
      };
    };
    "127" = {
      enabled = true;
      value = {
        type = "standard";
        parameters = [
          65535
          29
          524288
        ];
      };
    };
  };

  symbolichotkeyCommands = lib.mapAttrsToList (
    id: value:
    ''launchctl asuser "$(/usr/bin/id -u -- ${config.system.primaryUser})" /usr/bin/sudo --user=${config.system.primaryUser} -- /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${id} ${
      lib.escapeShellArg (lib.generators.toPlist { escape = true; } value)
    }''
  ) symbolichotkeys;
in
{
  system.defaults = {
    NSGlobalDomain = {
      AppleKeyboardUIMode = 0;
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.keyboard.fnState" = true;
      "com.apple.swipescrolldirection" = true;
    };

    LaunchServices.LSQuarantine = false;

    dock = {
      autohide = true;
      expose-group-apps = false;
      minimize-to-application = false;
      mru-spaces = false;
      persistent-apps = [ ];
      show-recents = false;
    };

    finder = {
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadPinch = true;
      TrackpadRightClick = true;
      TrackpadRotate = true;
      TrackpadThreeFingerDrag = false;
    };

    screencapture.target = "preview";

    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 1;
      ShowDayOfWeek = true;
      ShowSeconds = true;
    };

    CustomSystemPreferences = {
      "/Library/Preferences/SystemConfiguration/com.apple.DiskArbitration.diskarbitrationd.plist" = {
        DADisableEjectNotification = true;
      };
    };

    CustomUserPreferences = {
      NSGlobalDomain."com.apple.mouse.linear" = true;

      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      "com.apple.finder" = {
        FinderSpawnTab = false;
        NewWindowTargetPath = "file://${home}/";
      };

      "com.apple.universalaccess".showWindowTitlebarIcons = true;

      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        Clicking = true;
        TrackpadPinch = true;
        TrackpadRightClick = true;
        TrackpadRotate = true;
        TrackpadThreeFingerDrag = false;
      };

      "com.apple.AppleMultitouchTrackpad" = {
        Clicking = true;
        TrackpadPinch = true;
        TrackpadRightClick = true;
        TrackpadRotate = true;
        TrackpadThreeFingerDrag = false;
      };

      "com.apple.screencapture" = {
        showsCursor = true;
        style = "selection";
      };

      "com.apple.Safari" = {
        AutoOpenSafeDownloads = false;
        IncludeDevelopMenu = true;
        SendDoNotTrackHTTPHeader = true;
        ShowFullURLInSmartSearchField = true;
        WebKitDeveloperExtrasEnabledPreferenceKey = true;
      };

      "com.apple.ActivityMonitor".UpdatePeriod = 1;
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "applying com.apple.symbolichotkeys overrides for ${config.system.primaryUser}..." >&2
    ${lib.concatStringsSep "\n" symbolichotkeyCommands}
    launchctl asuser "$(/usr/bin/id -u -- ${config.system.primaryUser})" /usr/bin/sudo --user=${config.system.primaryUser} -- /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
