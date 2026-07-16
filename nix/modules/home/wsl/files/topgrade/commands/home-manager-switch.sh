#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/topgrade/commands/common/lib/dotfiles.sh"

cd "$DOTFILES_DIR"
nix_args=()
if [[ -n "${BOOTSTRAP_NO_FLAKE_UPDATE:-}" ]]; then
  nix_args+=(--no-update-lock-file)
fi
ACTIVATION=$(
  nix build \
    "${nix_args[@]}" \
    --no-link \
    --print-out-paths \
    '.#homeConfigurations."k0ch4nx@ubuntu-wsl".activationPackage'
)
"$ACTIVATION/activate"
