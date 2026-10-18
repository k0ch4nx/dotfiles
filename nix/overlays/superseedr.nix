final: prev:
let
  version = "1.0.16";
in
{
  superseedr = prev.rustPlatform.buildRustPackage {
    pname = "superseedr";
    inherit version;

    src = prev.fetchFromGitHub {
      owner = "Jagalite";
      repo = "superseedr";
      rev = "v${version}";
      hash = "sha256-RJTXeO0gD2HMP/og0XZNlC7OKbhfkltj7nQ9N7UnjZQ=";
    };

    cargoHash = "sha256-3g3IpuB9a9zVgdeuNG9iO0m7ZjYcCtuvxxMnaLVIXSA=";

    doCheck = false;

    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.openssl ];

    meta = with prev.lib; {
      description = "A supercharged BitTorrent client for the terminal";
      homepage = "https://github.com/Jagalite/superseedr";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;
      mainProgram = "superseedr";
    };
  };
}
