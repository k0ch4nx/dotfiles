final: prev:

{
  jankyborders = prev.jankyborders.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "andrewcincotta";
      repo = "JankyBorders";
      rev = "fe8e98aad091839640d769517adb1dcae427c064";
      hash = "sha256-Bq3Du0Fzh75EfHvOhz9vnOACI2JiToe1PWpa7rU8RTE=";
    };
  });
}
