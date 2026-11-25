final: prev:
let
  version = "1.1.0";

  src = prev.fetchFromGitHub {
    owner = "alfredjeanlab";
    repo = "ripcloc";
    rev = "v${version}";
    hash = "sha256-jaYqvhwpfRmUujpJSdPBKE3Egb0UkoQHeojw2Ld7RKQ=";
  };
in
{
  ripcloc = prev.rustPlatform.buildRustPackage {
    pname = "ripcloc";
    inherit version src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    meta = with prev.lib; {
      description = "Counts lines of code very fast";
      homepage = "https://github.com/alfredjeanlab/ripcloc";
      license = licenses.mit;
      mainProgram = "ripcloc";
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  };
}
