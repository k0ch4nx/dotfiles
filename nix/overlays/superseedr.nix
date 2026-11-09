final: prev:
let
  version = "1.0.17";
in
{
  superseedr = prev.rustPlatform.buildRustPackage {
    pname = "superseedr";
    inherit version;

    src = prev.fetchFromGitHub {
      owner = "Jagalite";
      repo = "superseedr";
      rev = "v${version}";
      hash = "sha256-NsEQmUFdI0Bl9kQX4Z2rF/tzkzMY/tI/5CPAIXDEJSg=";
    };

    cargoHash = "sha256-d7j5+QyYgKK+9y9roTRTkIm1QSjvI3YXSXWvfC2OP2s=";

    doCheck = false;

    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [
      prev.aws-lc
      prev.openssl
    ];

    meta = with prev.lib; {
      description = "A supercharged BitTorrent client for the terminal";
      homepage = "https://github.com/Jagalite/superseedr";
      license = licenses.gpl3Plus;
      platforms = platforms.unix;
      mainProgram = "superseedr";
    };
  };
}
