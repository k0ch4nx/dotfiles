let
  darwinOverlayPaths = [
    ./azahar.nix
    ./blender.nix
    ./dolphin-emu.nix
  ];

  onlyDarwin =
    path: final: prev:
    if prev.stdenv.isDarwin then (import path) final prev else { };
in
(builtins.map onlyDarwin darwinOverlayPaths)
