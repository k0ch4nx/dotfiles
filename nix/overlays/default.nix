let
  overlayPaths = [
    ./sheets.nix
    ./superseedr.nix
  ];

  darwinOverlayPaths = [
    ./azahar.nix
    ./blender.nix
    ./dolphin-emu.nix
    ./terminal-browser.nix
  ];

  onlyDarwin =
    path: final: prev:
    if prev.stdenv.isDarwin then (import path) final prev else { };
in
(builtins.map (path: import path) overlayPaths) ++ (builtins.map onlyDarwin darwinOverlayPaths)
