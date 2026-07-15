{
  config,
  lib,
  pkgs,
  ...
}:

let
  ghqRoot = "~${lib.removePrefix config.home.homeDirectory config.dotfiles.ghqRoot}";
  gitConfigDir = pkgs.linkFarm "git-config.d" [
    {
      name = "os";
      path = pkgs.writeText "git-config-os" ''
        [ghq]
            root = ${ghqRoot}
      '';
    }
    {
      name = "personal";
      path = pkgs.writeText "git-config-personal" ''
        [user]
            email = 95961982+k0ch4nx@users.noreply.github.com
            name = k0ch4nx
            signingKey = ~/.ssh/id_ed25519_sk_gh_sign_pers.pub
        [core]
            sshCommand = ssh -i ~/.ssh/id_ed25519_sk_gh_auth_pers -o IdentitiesOnly=yes
      '';
    }
    {
      name = "work";
      path = pkgs.writeText "git-config-work" ''
        [user]
            email = 291656850+honma1283@users.noreply.github.com
            name = honma1283
            signingKey = ~/.ssh/id_ed25519_gh_work.pub
        [core]
            sshCommand = ssh -i ~/.ssh/id_ed25519_gh_work -o IdentitiesOnly=yes
      '';
    }
  ];
in
{
  home.packages = with pkgs; [
    delta
    ghq
    git-lfs
  ];

  xdg.configFile = {
    "git/config".force = true;
    "git/config.d".source = gitConfigDir;
  };

  programs.git = {
    enable = true;

    includes = [
      { path = "~/.config/git/config.d/os"; }
      {
        condition = "gitdir:${ghqRoot}/${config.dotfiles.remote}/${config.dotfiles.user}/";
        path = "~/.config/git/config.d/personal";
      }
      {
        condition = "gitdir:${ghqRoot}/${config.dotfiles.remote}/honma1283/";
        path = "~/.config/git/config.d/work";
      }
      {
        condition = "gitdir:${ghqRoot}/${config.dotfiles.remote}/sep-dev/";
        path = "~/.config/git/config.d/work";
      }
    ];

    settings = {
      color.ui = "auto";
      commit.gpgsign = true;
      core = {
        autocrlf = false;
        editor = "nvim";
        ignoreCase = false;
        pager = "delta";
        quotepath = false;
        safecrlf = true;
      };
      delta.navigate = true;
      "filter \"lfs\"" = {
        clean = "git-lfs clean -- %f";
        process = "git-lfs filter-process";
        required = true;
        smudge = "git-lfs smudge -- %f";
      };
      gpg.format = "ssh";
      "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
      init.defaultBranch = "main";
      merge.conflictStyle = "zdiff3";
      rebase.autoStash = true;
      tag.gpgSign = true;
    };
  };
}
