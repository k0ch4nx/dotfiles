final: prev:
let
  version = "1.0.15";
in
{
  superseedr = prev.rustPlatform.buildRustPackage {
    pname = "superseedr";
    inherit version;

    src = prev.fetchFromGitHub {
      owner = "Jagalite";
      repo = "superseedr";
      rev = "v${version}";
      hash = "sha256-wbHq7Hml2bUJfyGEVM1P29x1uruLnCvmJbP1L7exDOc=";
    };

    cargoHash = "sha256-MJJvAOEPBjgwz7pcrTIdOFe404+Cw4h1fI5Vk0yG9G0=";

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
