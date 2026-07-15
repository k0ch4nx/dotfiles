#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

umask 022
REPO="$DOTFILES_DIR"
HOST_KEY="$REPO/secrets/hosts/macbook-pro-key.txt"
HOST_PUB="$REPO/secrets/hosts/macbook-pro.pub"
if [ ! -f "$HOST_KEY" ]; then
  mkdir -p "$(dirname "$HOST_KEY")"
  rage-keygen -o "$HOST_KEY"
fi
chmod 600 "$HOST_KEY"
rage-keygen -y "$HOST_KEY" > "$HOST_PUB"
git -C "$REPO" add -f "$HOST_PUB"
cd "$REPO"
nix run .#agenix-rekey.aarch64-darwin.rekey
