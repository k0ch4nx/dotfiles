final: prev:
let
  version = "0.7.0";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-KpzBGim3tu1KXbN/S+ENz45wUWU72arPcCjU/wgYhGo=";
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
      hash = "sha256-DxGr89iAoGhSRgW8NiZQF3jtpYF0+uurtx6sv/UCDs4=";
    };
  });
}
