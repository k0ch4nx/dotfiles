{ config, inputs, ... }:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = "k0ch4nx";
    autoMigrate = true;
    taps."jackielii/homebrew-tap" = inputs.homebrew-jackielii-tap;
    trust.casks = [ "jackielii/tap/skhd-zig" ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };

    greedyCasks = true;

    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [ ];

    casks = [
      "affinity"
      "android-studio"
      "appcleaner"
      "bettermouse"
      "chatgpt"
      "epic-games"
      "freecad"
      "gog-galaxy"
      "google-drive"
      "intellij-idea-oss"
      "jackielii/tap/skhd-zig"
      "kindavim"
      "macfuse"
      "minecraft"
      "nvidia-geforce-now"
      "obs"
      "onedrive"
      "parallels"
      "parsec"
      "prefs-editor"
      "steam"
      "steinberg-activation-manager"
      "steinberg-download-assistant"
      "steinberg-library-manager"
      "tor-browser"
    ];

    masApps = {
      "Blackmagic Disk Speed Test" = 425264550;
      "DaVinci Resolve" = 571213070;
      "GarageBand" = 682658836;
      "Keepa - Price Tracker" = 1533805339;
      "LINE" = 539883307;
      "Wayback Machine" = 1472432422;
      "wBlock" = 6746388723;
    };
  };
}
