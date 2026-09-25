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

  construct = pythonPackages.buildPythonPackage rec {
    pname = "construct";
    version = "2.8.8";
    format = "setuptools";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/b6/2c/66bab4fef920ef8caa3e180ea601475b2cbbe196255b18f1c58215940607/construct-2.8.8.tar.gz";
      hash = "sha256-G4S4FH9v0VvPZLc3w+isUQCBGtgMgwy0slRRQFEcQVc=";
    };
  };

  pyplayready = pythonPackages.buildPythonPackage rec {
    pname = "pyplayready";
    version = "0.8.5";
    format = "wheel";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/62/b7/9cd1ba51df6e77ee5cb775aee63d44ee36aaaf6ebe524bf67831725742e6/pyplayready-0.8.5-py3-none-any.whl";
      hash = "sha256-+UN+ZxHTXWh5nwhvGzOQkXfGNdSgNpdtRk3+vmAIx6s=";
    };

    pythonRelaxDeps = [ "cryptography" ];

    propagatedBuildInputs = with pythonPackages; [
      aiohttp
      click
      cryptography
      ecpy
      platformdirs
      pycryptodome
      pyyaml
      requests
    ] ++ [ construct ];

    pythonImportsCheck = [ "pyplayready" ];
  };

  pymp4 = pythonPackages.buildPythonPackage rec {
    pname = "pymp4";
    version = "1.4.0";
    format = "pyproject";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/a5/46/dfb3f5363fc71adaf419147fdcb93341029ca638634a5cc6f7e7446416b2/pymp4-1.4.0.tar.gz";
      hash = "sha256-vJ53cyqKFD00w4qoYqVBgHFiRpOOS/PgdYXRklK3e7U=";
    };

    build-system = [ pythonPackages.poetry-core ];
    dependencies = [ construct ];

    pythonImportsCheck = [ "pymp4.parser" ];
  };

  pywidevine = (pythonPackages.pywidevine.override { inherit pymp4; }).overridePythonAttrs (_: {
    patches = [ ];
  });
in
{
  gamdl = pythonPackages.buildPythonApplication rec {
    pname = "gamdl";
    version = "3.9.1";
    pyproject = true;

    src = prev.fetchPypi {
      inherit pname version;
      hash = "sha256-mxGeJqM3s7UevQrzAsv4BYbskxfX7vpJPspNhzYLySs=";
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
      pyplayready
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
