let
  overlayPaths = [
    ./gamdl.nix
    ./sheets.nix
    ./superseedr.nix
  ];

  darwinOverlayPaths = [
    ./azahar.nix
    ./omni.nix
    ./rift.nix
    ./terminal-browser.nix
  ];

  onlyDarwin =
    path: final: prev:
    if prev.stdenv.hostPlatform.isDarwin then (import path) final prev else { };
in
(builtins.map (path: import path) overlayPaths) ++ (builtins.map onlyDarwin darwinOverlayPaths)
