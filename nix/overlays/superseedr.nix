final: prev:
let
  version = "1.0.12";
in
{
  superseedr = prev.rustPlatform.buildRustPackage {
    pname = "superseedr";
    inherit version;

    src = prev.fetchFromGitHub {
      owner = "Jagalite";
      repo = "superseedr";
      rev = "v${version}";
      hash = "sha256-z/8c5oLMR/6GVpJ/ltXtUSOHVeG5d5MMeoStqrP8rxE=";
    };

    cargoHash = "sha256-FxKjZDOJS5sshRRVdCTnfYZfIK2SvkP6Hz3YhSE5kFQ=";

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
