{ inputs, ... }:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = "k0ch4nx";
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      # nix-homebrew's wrapper loses Homebrew's original PATH when auto-update
      # re-executes brew, which prevents brew bundle from finding mas.
      autoUpdate = false;
      upgrade = true;
      cleanup = "none";
    };

    greedyCasks = true;

    taps = [ ];

    brews = [ ];

    casks = [
      "android-studio"
      "bettermouse"
      "chatgpt"
      "epic-games"
      "freecad"
      "gog-galaxy"
      "google-drive"
      "intellij-idea-oss"
      "kindavim"
      "macfuse"
      "minecraft"
      "nvidia-geforce-now"
      "obs"
      "onedrive"
      "parsec"
      "prefs-editor"
      "steam"
      "steinberg-activation-manager"
      "steinberg-download-assistant"
      "steinberg-library-manager"
      "tor-browser"
      "unity-hub"
    ];

    masApps = {
      "Keepa - Price Tracker" = 1533805339;
      "LINE" = 539883307;
      "Wayback Machine" = 1472432422;
      "wBlock" = 6746388723;
    };
  };
}
