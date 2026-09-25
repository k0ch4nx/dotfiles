final: prev:
let
  version = "0.14.5";
in
{
  omni = prev.stdenvNoCC.mkDerivation {
    pname = "omni";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/hanxiao/omni-macos/releases/download/v${version}/Omni-${version}.dmg";
      hash = "sha256-PnvvuDhX9Ao3zoQM56jYGlbbIlLVweMWIszOMlzN7Rw=";
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
