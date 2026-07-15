#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

cd "$DOTFILES_DIR"
nix flake update
