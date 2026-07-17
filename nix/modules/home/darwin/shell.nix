{ config, lib, ... }:

{
  programs.zsh.profileExtra = lib.mkBefore ''
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || :
    source "${config.home.homeDirectory}/.orbstack/shell/init.zsh" 2>/dev/null || :

    export SHELL_SESSION_DIR="${config.xdg.stateHome}/zsh/sessions"
    export SHELL_SESSION_FILE="''${SHELL_SESSION_DIR}/''${TERM_SESSION_ID}"
  '';
}
