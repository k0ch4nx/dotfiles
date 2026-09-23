final: prev:
let
  version = "0.13.8";
in
{
  omni = prev.stdenvNoCC.mkDerivation {
    pname = "omni";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/hanxiao/omni-macos/releases/download/v${version}/Omni-${version}.dmg";
      hash = "sha256-1M68Ie/ib38Oa7GN4C/P8JuqijmNguV/1oQI3JnMrnY=";
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
