final: prev:
let
  version = "0.8.0";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-iGz3QRU3t0nNEvtZ/i/9LmUncCEyKWy14MkkuZVb4hQ=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    patches = (old.patches or [ ]) ++ [
      ./patches/rift/regular-xpc-apps.patch
      ./patches/rift/enter-fullscreen.patch
    ];

    doCheck = false;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-lhOc53eMJIpdO8iPylcN6I9N5WwMTT6XhaZwh4jD6So=";
    };
  });
}
