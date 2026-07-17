#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "usage: wsl.sh" >&2
  exit 2
fi

readonly BOOTSTRAP_NAME="wsl"
readonly EXPECTED_USER="k0ch4nx"
readonly DOTFILES_REF="${DOTFILES_REF:-main}"
readonly GHQ_ROOT="${HOME}/src"
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
fi
readonly SCRIPT_DIR

bootstrap_common=""
if [[ -n "${SCRIPT_DIR}" && -r "${SCRIPT_DIR}/common.sh" ]]; then
  common_script="${SCRIPT_DIR}/common.sh"
else
  command -v curl >/dev/null 2>&1 || {
    echo "bootstrap(wsl): curl is required to load common.sh" >&2
    exit 1
  }
  bootstrap_common="$(mktemp "${TMPDIR:-/tmp}/bootstrap-common.XXXXXX")"
  trap 'rm -f -- "${bootstrap_common}"' EXIT
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    "https://raw.githubusercontent.com/${EXPECTED_USER}/dotfiles/${DOTFILES_REF}/bootstrap/common.sh" \
    --output "${bootstrap_common}"
  common_script="${bootstrap_common}"
fi
readonly common_script

# shellcheck source=common.sh
source "${common_script}"

if is_ci; then
  [[ -n "${SCRIPT_DIR}" ]] || die "CI execution requires a checked-out bootstrap script"
  DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
else
  DOTFILES_DIR="${GHQ_ROOT}/${DOTFILES_REMOTE}/${DOTFILES_USER}/${DOTFILES_REPO}"
fi
readonly DOTFILES_DIR
readonly DOTFILES_HOST="${EXPECTED_USER}@ubuntu-wsl"
export DOTFILES_DIR DOTFILES_HOST

trap cleanup EXIT

[[ "$(uname -s)" == "Linux" ]] || die "this script only supports Linux under WSL"
[[ -r /proc/sys/kernel/osrelease ]] || die "cannot identify the WSL kernel"
grep -qi microsoft /proc/sys/kernel/osrelease || die "this script only supports WSL"

if ! is_ci; then
  [[ "$(id -un)" == "${EXPECTED_USER}" ]] || die "run this script as ${EXPECTED_USER}"
  [[ "${HOME}" == "/home/${EXPECTED_USER}" ]] || die "expected HOME=/home/${EXPECTED_USER}, found ${HOME}"
  [[ -r /dev/tty ]] || die "an interactive terminal is required"
  exec </dev/tty
fi

install_nix --daemon /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if is_ci; then
  run_flake_command home-manager-build
  run_flake_command dotfiles-check
  log "WSL bootstrap build completed successfully"
  exit
fi

clone_or_update_dotfiles

run_flake_command nix-update
run_flake_command home-manager-switch

run_optional_flake_command neovim-lazy
run_optional_flake_command neovim-treesitter
run_optional_flake_command neovim-mason
run_optional_flake_command neovim-codediff
run_optional_flake_command apt-upgrade

finish_optional_flake_commands

log "Bootstrap completed successfully"
