final: prev:

{
  jankyborders = prev.jankyborders.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "andrewcincotta";
      repo = "JankyBorders";
      rev = "43df02eab171fdd4c8983428fe0af7070de08754";
      hash = "sha256-COfEDShFm08QkskkTBcKfATxYX/kczLz4j9Abm4aD7c=";
    };
  });
}
