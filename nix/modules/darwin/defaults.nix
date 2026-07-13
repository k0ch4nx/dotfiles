{ config, ... }:

let
  inherit (config.users.users.k0ch4nx) home;
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
}
