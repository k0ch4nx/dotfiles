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

readonly YUBIKEY_IDENTITY="${HOME}/.config/age/yubikey-identity.txt"
readonly HOME_PATH_ATTRIBUTE="darwinConfigurations.macbook-pro.config.home-manager.users.${EXPECTED_USER}.home.path"
readonly DARWIN_REBUILD_ATTRIBUTE="darwinConfigurations.macbook-pro.config.system.build.darwin-rebuild"
readonly SYSTEM_ATTRIBUTE="darwinConfigurations.macbook-pro.config.system.build.toplevel"
readonly HOST_TOPGRADE_DIR="${DOTFILES_DIR}/nix/modules/home/darwin/files/topgrade"

prepare_command_line_tools() {
  if /usr/bin/xcode-select --print-path >/dev/null 2>&1; then
    return
  fi

  log "Requesting installation of the Xcode Command Line Tools"
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  die "complete the Command Line Tools installation, then run darwin.sh again"
}

prepare_yubikey_identity() {
  local home_path=$1
  local identity_tmp="${YUBIKEY_IDENTITY}.tmp.$$"
  local yubikey="${home_path}/bin/age-plugin-yubikey"

  [[ -x "${yubikey}" ]] || die "age-plugin-yubikey is missing from the Home Manager environment"

  if [[ -L "${YUBIKEY_IDENTITY}" && ! -e "${YUBIKEY_IDENTITY}" ]]; then
    rm -f -- "${YUBIKEY_IDENTITY}"
  fi
  if [[ -s "${YUBIKEY_IDENTITY}" ]]; then
    return
  fi

  log "Preparing the YubiKey identity"
  echo "Insert and unlock the YubiKey when prompted."
  mkdir -p "$(dirname "${YUBIKEY_IDENTITY}")"
  if ! (umask 077; "${yubikey}" --identity >"${identity_tmp}"); then
    rm -f -- "${identity_tmp}"
    die "failed to read the YubiKey identity"
  fi
  if [[ ! -s "${identity_tmp}" ]]; then
    rm -f -- "${identity_tmp}"
    die "no YubiKey identity was returned"
  fi
  chmod 600 "${identity_tmp}"
  mv "${identity_tmp}" "${YUBIKEY_IDENTITY}"
}

create_ci_dummy_secrets() {
  log "Creating dummy rekeyed secrets for the CI build"

  (
    cd "${DOTFILES_DIR}"
    nix_cmd run \
      --no-update-lock-file \
      "${DOTFILES_DIR}#agenix-rekey.aarch64-darwin.rekey" \
      -- --dummy
  )
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
  create_ci_dummy_secrets
  log "Building the macOS system without activating it"
  build_flake_path "${SYSTEM_ATTRIBUTE}" >/dev/null
  check_flake
  log "Darwin bootstrap build completed successfully"
  exit
fi

clone_or_update_dotfiles
echo "Ensure that the Mac App Store is signed in before Homebrew activation."

log "Building the Nix-managed Home Manager environment"
home_path="$(build_flake_path "${HOME_PATH_ATTRIBUTE}")"
prepare_yubikey_identity "${home_path}"

log "Building the flake-pinned darwin-rebuild"
darwin_rebuild="$(build_flake_path "${DARWIN_REBUILD_ATTRIBUTE}")"
run_topgrade \
  "${home_path}" \
  "${darwin_rebuild}/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${EXPECTED_USER}/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  "${HOST_TOPGRADE_DIR}"

log "Bootstrap completed successfully"
