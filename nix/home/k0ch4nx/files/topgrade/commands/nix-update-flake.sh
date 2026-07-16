#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_NO_FLAKE_UPDATE:-}" ]]; then
  echo "Skipping the flake input update during bootstrap"
  exit
fi

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

cd "$DOTFILES_DIR"
nix flake update
