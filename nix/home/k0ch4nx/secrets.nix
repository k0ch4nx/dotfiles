{ config, ... }:

let
  envFiles = builtins.readDir ../../../secrets/env;
  envSecretNames = builtins.map
    (fileName: builtins.substring 0 (builtins.stringLength fileName - 4) fileName)
    (builtins.filter
      (fileName: envFiles.${fileName} == "regular" && builtins.match ".*\\.age" fileName != null)
      (builtins.attrNames envFiles));
in
{
  age.secrets = builtins.listToAttrs (
    builtins.map (name: {
      name = "env-${name}";
      value = {
        file = ../../../secrets/env/${name}.age;
        path = "${config.programs.zsh.dotDir}/env/${name}";
        mode = "600";
      };
    }) envSecretNames
  );
}
