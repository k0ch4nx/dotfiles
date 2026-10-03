final: prev:
let
  version = "0.13.4";
in
{
  terminal-browser = prev.stdenv.mkDerivation {
    pname = "terminal-browser";
    inherit version;

    src = prev.fetchurl {
      url = "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-darwin-arm64.tar.gz";
      sha256 = "sha256-8BcjDHjGCgfvRFGh6wqScn8LlVqPzYeuw1iRDF0MA8c=";
    };

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/terminal-browser"
      tar -xzf "$src" -C "$out/terminal-browser" --strip-components 1
      cat > "$out/bin/terminal-browser" <<EOF
      #!/bin/sh
      exec "$out/terminal-browser/bin/terminal-browser" "\$@"
      EOF
      chmod +x "$out/bin/terminal-browser"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "A real browser that runs inside your terminal";
      homepage = "https://terminal-browser.com";
      license = licenses.unfree;
      platforms = [ "aarch64-darwin" ];
    };
  };
}
