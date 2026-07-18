{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs = {
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      history = {
        path = "${config.xdg.stateHome}/zsh/history";
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };

      autosuggestion.enable = true;

      plugins = [
        {
          name = "zsh-history-substring-search";
          src = "${pkgs.zsh-history-substring-search}/share/zsh/plugins/zsh-history-substring-search";
        }
        {
          name = "fast-syntax-highlighting";
          src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
        }
        {
          name = "zsh-vi-mode";
          src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
        }
      ];

      initContent = lib.mkBefore ''
        ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

        setopt globdots

        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
        zle_highlight=(''${zle_highlight:#paste:*} paste:standout)

        zstyle ":completion:*" menu select
        zstyle ":completion:*" cache-path "${config.xdg.cacheHome}/zsh/.zcompcache"

        source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"

        # gcloud completion
        if type brew &>/dev/null && [ -f "$(brew --prefix)/share/zsh/site-functions/_google_cloud_sdk" ]; then
          source "$(brew --prefix)/share/zsh/site-functions/_google_cloud_sdk"
        fi

        # rustup completions
        if command -v rustup &>/dev/null; then
          source <(rustup completions zsh rustup)
        fi

        function zvm_after_init() {
          if command -v fzf &>/dev/null; then
            source <(fzf --zsh)
          fi
        }

        bindkey -M vicmd "k" history-substring-search-up
        bindkey -M vicmd "j" history-substring-search-down

        function eza() {
          local opts=(
            "--long"
            "--color=always"
            "--color-scale=age"
            "--color-scale-mode=gradient"
            "--icons=auto"
            "--hyperlink"
            "--all"
            "--group-directories-first"
            "--binary"
            "--header"
            "--links"
            "--modified"
            "--mounts"
            "--blocksize"
            "--accessed"
            "--created"
            "--changed"
            "--git"
            "--git-repos"
            "--time-style=long-iso"
            "--total-size"
            "--octal-permissions"
          )
          command eza "''${opts[@]}" "$@"
        }

        function gamdl() {
          command gamdl --config-path "${config.xdg.configHome}/gamdl/config.ini" "$@"
        }

        function ghqf() {
          local eza_opts=(
            "--long"
            "--color=always"
            "--color-scale=age"
            "--color-scale-mode=gradient"
            "--icons=auto"
            "--all"
            "--group-directories-first"
            "--git"
            "--no-permissions"
            "--no-filesize"
            "--no-user"
            "--no-time"
          )
          local preview_cmd="eza $(ghq root)/{} ''${eza_opts[@]}"
          cd "$(ghq root)/$(ghq list | fzf --preview "''${preview_cmd}")"
        }

        if command -v fastfetch &>/dev/null; then
          if [ ''${SHLVL} -eq 1 ]; then
            fastfetch
          fi
        fi
      '';

      completionInit = ''
        if type brew &>/dev/null; then
          FPATH="$(brew --prefix)/share/zsh/site-functions:''${FPATH}"
        fi
        if command -v rustc &>/dev/null; then
          FPATH="$(rustc --print sysroot)/share/zsh/site-functions:''${FPATH}"
        fi

        autoload -Uz compinit
        compinit -d "${config.xdg.cacheHome}/zsh/.zcompdump"

        autoload -U +X bashcompinit
        bashcompinit

        if command -v terraform &>/dev/null; then
          complete -o nospace -C "$(command -v terraform)" terraform
        fi
      '';

      profileExtra = ''
        # Ensure Nix profiles take precedence over other binaries.
        export PATH="/etc/profiles/per-user/${config.home.username}/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
      '';

      envExtra = ''
        if [ -f "${config.programs.zsh.dotDir}/env/gh-token" ]; then
          export GH_TOKEN="$(tr -d '\n' < "${config.programs.zsh.dotDir}/env/gh-token")"
        fi
        if [ -f "${config.programs.zsh.dotDir}/env/mem0-api-key" ]; then
          export MEM0_API_KEY="$(tr -d '\n' < "${config.programs.zsh.dotDir}/env/mem0-api-key")"
        fi
        if [ -f "${config.programs.zsh.dotDir}/env/skillsmp-api-key" ]; then
          export SKILLSMP_API_KEY="$(tr -d '\n' < "${config.programs.zsh.dotDir}/env/skillsmp-api-key")"
        fi
      '';
    };

    oh-my-posh = {
      enable = true;
      configFile = "${config.xdg.configHome}/oh-my-posh/themes/default.json";
    };

    fzf = {
      enable = true;
      enableZshIntegration = false;
    };
  };

  xdg = {
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";

    configFile = {
      "fzf".source = ./files/fzf;
      "oh-my-posh".source = ./files/oh-my-posh;
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.lmstudio/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.sessionVariables = {
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_STATE_HOME = "${config.xdg.stateHome}";

    DO_NOT_TRACK = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    OMO_SEND_ANONYMOUS_TELEMETRY = "0";
    HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";

    FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/fzfrc";

    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    GOPATH = "${config.xdg.dataHome}/go";
    LESSHISTFILE = "${config.xdg.stateHome}/less/lesshst";

    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

    OPENCODE_DISABLE_CLAUDE_CODE = "1";

    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";

    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python/__pycache__";
    PYTHON_HISTORY = "${config.xdg.dataHome}/python/.python_history";

    TF_CLI_CONFIG_FILE = "${config.xdg.configHome}/terraform/terraform.tfrc";
  };
}
