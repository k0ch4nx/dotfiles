let
  darwinOverlayPaths = [
    ./azahar.nix
    ./blender.nix
    ./dolphin-emu.nix
    ./sfml.nix
    ./whisper-cpp.nix
  ];

  onlyDarwin =
    path: final: prev:
    if prev.stdenv.isDarwin then (import path) final prev else { };
in
(builtins.map onlyDarwin darwinOverlayPaths)
