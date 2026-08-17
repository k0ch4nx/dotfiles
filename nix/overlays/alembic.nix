final: prev: {
  # Alembic 1.8.12 from nixpkgs PR #450978 creates a Darwin dev/lib output cycle; remove this rollback once upstream fixes the output split.
  alembic = prev.alembic.overrideAttrs (_: {
    version = "1.8.8";
    src = prev.fetchFromGitHub {
      owner = "alembic";
      repo = "alembic";
      tag = "1.8.8";
      hash = "sha256-R69UYyvLnMwv1JzEQ6S6elvR83Rmvc8acBJwSV/+hCk=";
    };
  });
}
