final: prev:
let
  version = "0.28.27";

  assets = {
    aarch64-darwin = {
      name = "plannotator-darwin-arm64";
      hash = "sha256-lSr20xwlaGGsfR0DjEUQiyZDkHPgtst7nVuCugizfWw=";
    };
    x86_64-linux = {
      name = "plannotator-linux-x64";
      hash = "sha256-VUQv44uI0Dn8IR1y2mJFzx1YaGuuOk+LGNY4IeF4WTg=";
    };
  };

  system = prev.stdenv.hostPlatform.system;
  asset = assets.${system} or null;
in
if asset == null then
  { }
else
  {
    plannotator = prev.stdenvNoCC.mkDerivation {
      pname = "plannotator";
      inherit version;

      src = prev.fetchurl {
        url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/${asset.name}";
        inherit (asset) hash;
      };

      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        cp "$src" "$out/bin/plannotator"
        chmod 755 "$out/bin/plannotator"
        runHook postInstall
      '';

      meta = with prev.lib; {
        description = "Annotate and review coding agent plans, diffs, and documents in a local browser UI";
        homepage = "https://plannotator.ai";
        license = with licenses; [
          asl20
          mit
        ];
        mainProgram = "plannotator";
        platforms = builtins.attrNames assets;
        sourceProvenance = [ sourceTypes.binaryNativeCode ];
      };
    };
  }
