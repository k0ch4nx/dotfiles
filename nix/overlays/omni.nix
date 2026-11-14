final: prev:
let
  version = "0.20.3";
in
{
  omni = prev.stdenvNoCC.mkDerivation {
    pname = "omni";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/hanxiao/omni-macos/releases/download/v${version}/Omni-${version}.dmg";
      hash = "sha256-HTxkteaStlnEXb/PDtK5SzW+uJkJioFrYtwV+sxsbr0=";
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
