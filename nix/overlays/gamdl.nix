final: prev:
let
  pythonPackages = prev.python313Packages;

  dataclassClick = pythonPackages.buildPythonPackage rec {
    pname = "dataclass-click";
    version = "1.0.4";
    format = "wheel";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/86/dc/38a94a2eb5f756724a6dc87a7aea38f7b747fe7b2e9daabc34a65e6cd9ac/dataclass_click-1.0.4-py3-none-any.whl";
      hash = "sha256-oiXTDATkq726QRzD1ewKLqgp4dymUAr+X4fMJD5erXI=";
    };

    propagatedBuildInputs = [ pythonPackages.click ];
  };
in
{
  gamdl = pythonPackages.buildPythonApplication rec {
    pname = "gamdl";
    version = "3.8.5";
    pyproject = true;

    src = prev.fetchPypi {
      inherit pname version;
      hash = "sha256-1oMTlRi2FgP3otpiovebCb+/WhKUiz9DrVKCTdhfenM=";
    };

    cargoRoot = "gamdl/downloader/ammuxer";
    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      cargoRoot = "gamdl/downloader/ammuxer";
      hash = "sha256-qUpS+FxPxGt+692epTQLXjN1BsD2Wi0XK6lHnwArpu8=";
    };

    nativeBuildInputs = with prev.rustPlatform; [
      cargoSetupHook
      maturinBuildHook
    ];

    buildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [ prev.libiconv ];

    dependencies = with pythonPackages; [
      async-lru
      click
      colorama
      dataclassClick
      httpx
      httpx-retries
      inquirerpy
      m3u8
      mutagen
      pillow
      pywidevine
      structlog
      yt-dlp
    ];

    doCheck = false;
    doInstallCheck = false;

    meta = with prev.lib; {
      description = "Apple Music downloader";
      homepage = "https://github.com/glomatico/gamdl";
      license = licenses.mit;
      mainProgram = "gamdl";
      platforms = platforms.unix;
    };
  };
}
