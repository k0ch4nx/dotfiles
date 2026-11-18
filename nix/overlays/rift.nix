final: prev:
let
  version = "0.8.3";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-8imLFJ90Ovb9y19iTN+JgQ+FtiKx7pbgpPzdSl4Agug=";
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
      hash = "sha256-OOQhpopVGKhS2QHfRuapVBx6bZdZAxNlOHM54c5JvxI=";
    };
  });
}
