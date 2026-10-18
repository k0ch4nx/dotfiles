final: prev:
let
  version = "0.17.3";
in
{
  omni = prev.stdenvNoCC.mkDerivation {
    pname = "omni";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/hanxiao/omni-macos/releases/download/v${version}/Omni-${version}.dmg";
      hash = "sha256-4VXbod362RQ6107GWi5rP9OnmoSHvpqzPFGzrV7vU5s=";
    };

    nativeBuildInputs = [ prev.undmg ];

    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -a Omni.app "$out/Applications"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "On-device semantic search over your local files";
      homepage = "https://hanxiao.io/omni/";
      license = licenses.asl20;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
