let
  commonOverlayPaths = [
    ./commitizen.nix
  ];

  darwinOverlayPaths = [
    ./azahar.nix
    ./blender.nix
    ./dolphin-emu.nix
    ./mpv.nix
    ./qbittorrent.nix
    ./sfml.nix
    ./whisper-cpp.nix
  ];

  onlyDarwin =
    path: final: prev:
    if prev.stdenv.isDarwin then (import path) final prev else { };
in
(builtins.map (path: import path) commonOverlayPaths)
++ (builtins.map onlyDarwin darwinOverlayPaths)
