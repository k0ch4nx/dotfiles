let
  publicKeys = [
    "age1yubikey1qtum9xqdvxfhh7ucyv0ep7hg0ykym234aez8g4j77fdw9h9pac7wxnazp8e"
    "age1kleelkfhfkqc2mysqsu0x0e6atczl97xx7mrssvm726qnh8n6p0sdmrj3q"
    "age17g60crsnym8rzg34fmwctvgsczjyn0chz68srmfw7vuaxahlesmqhxzxjh"
    "age1mf0qz0sjr7vxh50ffk4xjfkcgl9vmvd3a9r8gymvd5zlhddrd5asl4quw3"
  ];
  envFiles = builtins.readDir ./env;
  envSecretNames =
    builtins.map (fileName: builtins.substring 0 (builtins.stringLength fileName - 4) fileName)
      (
        builtins.filter (
          fileName: envFiles.${fileName} == "regular" && builtins.match ".*\\.age" fileName != null
        ) (builtins.attrNames envFiles)
      );
  requiredSecretNames = (builtins.map (name: "env/${name}.age") envSecretNames) ++ [
    "hcp-terraform-token.age"
    "ssh/id_ed25519.age"
    "ssh/id_ed25519_gh_work.age"
    "ssh/id_ed25519_sk.age"
    "ssh/id_ed25519_sk_gh_auth_pers.age"
    "ssh/id_ed25519_gh_sign_pers.age"
  ];
  optionalSecretNames = [
    "nix-cache-local-private-key.age"
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
