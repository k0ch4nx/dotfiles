{
  inputs,
  config,
  lib,
  ...
}:

{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.agenix-rekey.homeManagerModules.default
    ../../modules/rekey.nix
  ];

  age = {
    identityPaths = [
      "/Users/k0ch4nx/Developer/github.com/k0ch4nx/dotfiles/secrets/hosts/MacBook-Pro-key.txt"
    ];

    secrets = {
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
      "ssh-id_ed25519" = {
        rekeyFile = ../../../secrets/ssh/id_ed25519.age;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
        mode = "600";
      };
      "ssh-id_ed25519_gh_work" = {
        rekeyFile = ../../../secrets/ssh/id_ed25519_gh_work.age;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519_gh_work";
        mode = "600";
      };
      "ssh-id_ed25519_sk" = {
        rekeyFile = ../../../secrets/ssh/id_ed25519_sk.age;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
        mode = "600";
      };
      "ssh-id_ed25519_sk_gh_auth_pers" = {
        rekeyFile = ../../../secrets/ssh/id_ed25519_sk_gh_auth_pers.age;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_gh_auth_pers";
        mode = "600";
      };
      "ssh-id_ed25519_sk_gh_sign_pers" = {
        rekeyFile = ../../../secrets/ssh/id_ed25519_sk_gh_sign_pers.age;
        path = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_gh_sign_pers";
        mode = "600";
      };
    };
  };

  launchd.agents.activate-agenix.config.KeepAlive = lib.mkForce false;
}
