let
  publicKeys = [
    "age1yubikey1qv4j58tmzzfvtu03zn0mmfwtp7e9p0324lf0u22hkd6raveqlascczcwtly"
    "age1kleelkfhfkqc2mysqsu0x0e6atczl97xx7mrssvm726qnh8n6p0sdmrj3q"
  ];
  requiredSecretNames = [
    "env/gh-token.age"
    "env/mem0-api-key.age"
    "env/skillsmp-api-key.age"
    "ssh/id_ed25519.age"
    "ssh/id_ed25519_gh_work.age"
    "ssh/id_ed25519_sk.age"
    "ssh/id_ed25519_sk_gh_auth_pers.age"
    "ssh/id_ed25519_sk_gh_sign_pers.age"
  ];
  optionalSecretNames = [
    "nix-cache-local-private-key.age"
    "r2-credentials.age"
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
