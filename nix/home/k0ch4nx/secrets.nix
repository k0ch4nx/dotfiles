{ config, ... }:

{
  age.secrets = {
    "env-gh-token" = {
      rekeyFile = ../../../secrets/env/gh-token.age;
      path = "${config.programs.zsh.dotDir}/env/gh-token";
      mode = "600";
    };

    "env-mem0-api-key" = {
      rekeyFile = ../../../secrets/env/mem0-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/mem0-api-key";
      mode = "600";
    };

    "env-skillsmp-api-key" = {
      rekeyFile = ../../../secrets/env/skillsmp-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/skillsmp-api-key";
      mode = "600";
    };

    "env-gemini-api-key" = {
      rekeyFile = ../../../secrets/env/gemini-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/gemini-api-key";
      mode = "600";
    };

    "env-nvidia-api-key" = {
      rekeyFile = ../../../secrets/env/nvidia-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/nvidia-api-key";
      mode = "600";
    };

    "env-opencode-api-key" = {
      rekeyFile = ../../../secrets/env/opencode-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/opencode-api-key";
      mode = "600";
    };

    "env-openrouter-api-key" = {
      rekeyFile = ../../../secrets/env/openrouter-api-key.age;
      path = "${config.programs.zsh.dotDir}/env/openrouter-api-key";
      mode = "600";
    };
  };
}
