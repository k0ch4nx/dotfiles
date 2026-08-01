final: prev:
let
  version = "0.3.0";
in
{
  sheets = prev.buildGoModule {
    pname = "sheets";
    inherit version;

    src = prev.fetchFromGitHub {
      owner = "maaslalani";
      repo = "sheets";
      rev = "v${version}";
      hash = "sha256-xDu+jbWH7ubXC6ImvkRVgPI0OHAaUQ60sELDJN8hY1M=";
    };

    vendorHash = "sha256-X7bfALH9mM15HP6SM60CFIG1rm4Ma6LEh2p7z5LNW64=";

    meta = with prev.lib; {
      description = "A simple spreadsheet for the terminal";
      homepage = "https://github.com/maaslalani/sheets";
      license = licenses.mit;
      platforms = platforms.all;
      mainProgram = "sheets";
    };
  };
}
