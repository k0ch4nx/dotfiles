# Backport nixpkgs PR #584733 until the locked nixpkgs includes it.
final: prev: {
  pyrefly = prev.pyrefly.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];
  });
}
