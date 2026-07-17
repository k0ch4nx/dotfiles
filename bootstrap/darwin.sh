#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "usage: darwin.sh" >&2
  exit 2
fi

readonly BOOTSTRAP_NAME="darwin"
readonly EXPECTED_USER="k0ch4nx"
readonly DOTFILES_REF="${DOTFILES_REF:-main}"
readonly GHQ_ROOT="${HOME}/Developer"
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
    echo "bootstrap(darwin): curl is required to load common.sh" >&2
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
readonly DOTFILES_HOST="macbook-pro"
export DOTFILES_DIR DOTFILES_HOST

prepare_command_line_tools() {
  if /usr/bin/xcode-select --print-path >/dev/null 2>&1; then
    return
  fi

  log "Requesting installation of the Xcode Command Line Tools"
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  die "complete the Command Line Tools installation, then run darwin.sh again"
}

trap cleanup EXIT

[[ "$(uname -s)" == "Darwin" ]] || die "this script only supports macOS"
[[ "$(uname -m)" == "arm64" ]] || die "this script only supports Apple Silicon Macs"

if ! is_ci; then
  [[ "$(id -un)" == "${EXPECTED_USER}" ]] || die "run this script as ${EXPECTED_USER}"
  [[ "${HOME}" == "/Users/${EXPECTED_USER}" ]] || die "expected HOME=/Users/${EXPECTED_USER}, found ${HOME}"
  [[ -r /dev/tty ]] || die "an interactive terminal is required"
  exec </dev/tty
fi

prepare_command_line_tools
install_nix --daemon /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if is_ci; then
  run_flake_command darwin-ci-secrets
  run_flake_command darwin-build
  run_flake_command dotfiles-check
  log "Darwin bootstrap build completed successfully"
  exit
fi

clone_or_update_dotfiles

run_flake_command nix-update
run_flake_command agenix-rekey
run_flake_command darwin-switch

run_optional_flake_command homebrew-clean-build-dependencies
run_optional_flake_command neovim-lazy
run_optional_flake_command neovim-treesitter
run_optional_flake_command neovim-mason
run_optional_flake_command neovim-codediff
run_optional_flake_command github-cli-extensions
run_optional_flake_command rustup-update
run_optional_flake_command ferium-upgrade
run_optional_flake_command macos-update

finish_optional_flake_commands

log "Bootstrap completed successfully"
