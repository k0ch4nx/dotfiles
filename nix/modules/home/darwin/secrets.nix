{
  config,
  lib,
  ...
}:

{
  age = {
    secrets = {
      "env-gh-token" = {
        rekeyFile = ../../../../secrets/env/gh-token.age;
        path = "${config.programs.zsh.dotDir}/env/gh-token";
        mode = "600";
      };
      "env-mem0-api-key" = {
        rekeyFile = ../../../../secrets/env/mem0-api-key.age;
        path = "${config.programs.zsh.dotDir}/env/mem0-api-key";
        mode = "600";
      };
      "env-skillsmp-api-key" = {
        rekeyFile = ../../../../secrets/env/skillsmp-api-key.age;
        path = "${config.programs.zsh.dotDir}/env/skillsmp-api-key";
        mode = "600";
      };
    };
  };

  launchd.agents.activate-agenix.config.KeepAlive = lib.mkForce false;
}
