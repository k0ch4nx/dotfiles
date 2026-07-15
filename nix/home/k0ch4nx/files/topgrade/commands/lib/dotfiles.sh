#!/usr/bin/env bash

set -euo pipefail

readonly DOTFILES_PATH_FILE="$HOME/.config/dotfiles/path"

if [[ ! -r "$DOTFILES_PATH_FILE" ]]; then
  echo "dotfiles path file is not readable: $DOTFILES_PATH_FILE" >&2
  exit 1
fi

DOTFILES_DIR="$(<"$DOTFILES_PATH_FILE")"
readonly DOTFILES_DIR

if [[ -z "$DOTFILES_DIR" ]]; then
  echo "dotfiles path file is empty: $DOTFILES_PATH_FILE" >&2
  exit 1
fi
