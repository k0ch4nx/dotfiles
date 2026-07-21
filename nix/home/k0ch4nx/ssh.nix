{ config, ... }:

{
  age.secrets = {
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

  home.file = {
    ".ssh/allowed_signers".source = ./files/ssh/allowed_signers;
    ".ssh/authorized_keys".source = ./files/ssh/authorized_keys;
    ".ssh/config".source = ./files/ssh/config;
    ".ssh/id_ed25519.pub".source = ./files/ssh/id_ed25519.pub;
    ".ssh/id_ed25519_gh_work.pub".source = ./files/ssh/id_ed25519_gh_work.pub;
    ".ssh/id_ed25519_sk.pub".source = ./files/ssh/id_ed25519_sk.pub;
    ".ssh/id_ed25519_sk_gh_auth_pers.pub".source = ./files/ssh/id_ed25519_sk_gh_auth_pers.pub;
    ".ssh/id_ed25519_sk_gh_sign_pers.pub".source = ./files/ssh/id_ed25519_sk_gh_sign_pers.pub;
  };
}
