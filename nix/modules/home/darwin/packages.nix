{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    _010editor
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    apparency
    azahar
    betterdisplay
    blender
    discord
    dolphin-emu
    fabric-installer
    ferium
    ghidra
    google-chrome
    iina
    jankyborders
    lmstudio
    mas
    orbstack
    qbittorrent
    ryubing
    skhd
    udev-gothic-nf
    (vscode.overrideAttrs (old: {
      postPatch =
        builtins.replaceStrings
          [ "Contents/Resources/app/node_modules/@vscode/ripgrep-universal" ]
          [ "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal" ]
          old.postPatch;
    }))
    wezterm
    yabai
  ];
}
