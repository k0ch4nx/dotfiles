#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

cd "$DOTFILES_DIR"
ACTIVATION=$(nix build --no-link --print-out-paths '.#homeConfigurations."k0ch4nx@ubuntu-wsl".activationPackage')
"$ACTIVATION/activate"
