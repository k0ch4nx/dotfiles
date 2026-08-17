let
  withLld = import ./with-lld.nix { pname = "azahar"; };
in
final: prev:
let
  lldPackages = withLld final prev;
in
lldPackages
// {
  azahar = lldPackages.azahar.overrideAttrs (
    old:
    let
      oldEnv = old.env or { };
    in
    {
      # Azahar 2126.0 requires system MoltenVK after upstream PR #2183.
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUSE_SYSTEM_MOLTENVK:BOOL=TRUE" ];

      # Azahar PR #2149 introduced CAMetalLayer usage without linking QuartzCore.
      env = oldEnv // {
        NIX_CFLAGS_LINK = "${oldEnv.NIX_CFLAGS_LINK or ""} -framework QuartzCore";
      };
    }
  );
}
