#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

cd "$DOTFILES_DIR"
darwin_args=()
if [[ -n "${BOOTSTRAP_NO_FLAKE_UPDATE:-}" ]]; then
  darwin_args+=(--no-update-lock-file)
fi
sudo darwin-rebuild switch "${darwin_args[@]}" --flake .#macbook-pro
