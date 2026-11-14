final: prev:
let
  version = "0.8.2";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-cLFGVkPF7qGgC4QIyEc8b9rZ0LB8PoH7golgwT59ZRA=";
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
      hash = "sha256-XFn/DXOimu4gkgOXKDgZ/RBVxida7mvq1+lMx0Wrt/4=";
    };
  });
}
