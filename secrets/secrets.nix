let
  publicKeys = [
    "age1yubikey1qtum9xqdvxfhh7ucyv0ep7hg0ykym234aez8g4j77fdw9h9pac7wxnazp8e"
    "age1kleelkfhfkqc2mysqsu0x0e6atczl97xx7mrssvm726qnh8n6p0sdmrj3q"
  ];
  requiredSecretNames = [
    "env/gh-token.age"
    "env/gemini-api-key.age"
    "env/mem0-api-key.age"
    "env/nvidia-api-key.age"
    "env/opencode-api-key.age"
    "env/openrouter-api-key.age"
    "env/skillsmp-api-key.age"
    "ssh/id_ed25519.age"
    "ssh/id_ed25519_gh_work.age"
    "ssh/id_ed25519_sk.age"
    "ssh/id_ed25519_sk_gh_auth_pers.age"
    "ssh/id_ed25519_sk_gh_sign_pers.age"
  ];
  optionalSecretNames = [
    "nix-cache-local-private-key.age"
    "r2-access-key-id.age"
    "r2-secret-access-key.age"
  ];
  secretNames =
    requiredSecretNames ++ builtins.filter (name: builtins.pathExists ./${name}) optionalSecretNames;
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = {
      inherit publicKeys;
      armor = true;
    };
  }) secretNames
)
