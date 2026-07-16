{ pkgs, ... }:

pkgs.runCommand "nix-format"
  {
    nativeBuildInputs = [
      pkgs.findutils
      pkgs.nixfmt
    ];
    src = ../..;
  }
  ''
    cp -R "$src" source
    chmod -R u+w source
    find source -type f -name '*.nix' -print0 \
      | xargs -0 nixfmt --check
    touch "$out"
  ''
