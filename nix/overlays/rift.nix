final: prev:
let
  version = "0.8.6";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-tX0BgpF9K24Q71WFZO/OhqT/S4o0u7GeBdaWXbhkb90=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    patches = (old.patches or [ ]) ++ [
      ./patches/rift/regular-xpc-apps.patch
    ];

    doCheck = false;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-dJsjOZklzevu6SyeOHynPlt3vU3iJzQE5v4Y5vCIe/4=";
    };
  });
}
