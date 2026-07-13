{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
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
