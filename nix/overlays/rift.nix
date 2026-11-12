final: prev:
let
  version = "0.8.1";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-7YSffWhF4ZqFuArWOrLKxXCzPLkTXSqlyJ9QeAi06u8=";
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
      hash = "sha256-AgHR8thBePobjqe2r4H53m6W0b6GEI5V7BK+gjDdU9A=";
    };
  });
}
