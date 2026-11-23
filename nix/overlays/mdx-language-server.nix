final: prev:
let
  version = "0.6.4";
in
{
  mdx-language-server = prev.buildNpmPackage rec {
    pname = "mdx-language-server";
    inherit version;

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@mdx-js/language-server/-/language-server-${version}.tgz";
      hash = "sha256-bbG13FAnRYd58DkK0cRUU6Pq/AP25C/jUgfSgQMumVs=";
    };

    postPatch = ''
      ln -s ${./mdx-language-server/package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-MAoUGLnirlBtAXPf8YCn6BMFIXzLGVsDpOIlrdkiB3c=";

    dontNpmBuild = true;

    meta = with prev.lib; {
      description = "Language server for MDX";
      homepage = "https://github.com/mdx-js/mdx-analyzer/tree/main/packages/language-server";
      changelog = "https://github.com/mdx-js/mdx-analyzer/blob/@mdx-js/language-server@${version}/packages/language-server/CHANGELOG.md";
      license = licenses.mit;
      maintainers = with maintainers; [ ThaoTranLePhuong ];
      mainProgram = "mdx-language-server";
    };
  };
}
