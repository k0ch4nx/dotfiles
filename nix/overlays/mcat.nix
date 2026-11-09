final: prev: {
  mcat-unwrapped = prev.mcat-unwrapped.overrideAttrs (old: {
    RUSTONIG_SYSTEM_LIBONIG = "1";
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.aws-lc
      prev.oniguruma
    ];
  });
}
