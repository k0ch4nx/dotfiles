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

readonly ACTIVATION_ATTRIBUTE="homeConfigurations.\"${EXPECTED_USER}@ubuntu-wsl\".activationPackage"
readonly HOME_PATH_ATTRIBUTE="homeConfigurations.\"${EXPECTED_USER}@ubuntu-wsl\".config.home.path"
readonly HOST_TOPGRADE_DIR="${DOTFILES_DIR}/nix/modules/home/wsl/files/topgrade"

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

install_nix --no-daemon "${HOME}/.nix-profile/etc/profile.d/nix.sh"

if is_ci; then
  log "Building the WSL Home Manager activation package"
  activation_package="$(build_flake_path "${ACTIVATION_ATTRIBUTE}")"
  [[ -x "${activation_package}/activate" ]] || die "Home Manager activation script is missing"
  check_flake
  log "WSL bootstrap build completed successfully"
  exit
fi

clone_or_update_dotfiles

log "Building the Nix-managed Home Manager environment"
home_path="$(build_flake_path "${HOME_PATH_ATTRIBUTE}")"
run_topgrade "${home_path}" "" "${HOST_TOPGRADE_DIR}"

log "Bootstrap completed successfully"
