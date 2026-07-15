#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "usage: darwin.sh [--check]" >&2
  exit 2
fi

readonly MODE="${1:-apply}"
readonly EXPECTED_USER="k0ch4nx"
readonly DOTFILES_REF="${DOTFILES_REF:-main}"
readonly DOTFILES_REPOSITORY="https://github.com/k0ch4nx/dotfiles.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
DOTFILES_DIR=""

if [[ "${MODE}" == "--check" ]]; then
  DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
elif [[ "${MODE}" == "apply" ]]; then
  DOTFILES_DIR="${HOME}/Developer/github.com/k0ch4nx/dotfiles"
else
  echo "usage: darwin.sh [--check]" >&2
  exit 2
fi
readonly DOTFILES_DIR

readonly YUBIKEY_IDENTITY="${HOME}/.config/age/yubikey-identity.txt"
readonly HOST_KEY="${DOTFILES_DIR}/secrets/hosts/macbook-pro-key.txt"
readonly HOST_PUBLIC_KEY="${DOTFILES_DIR}/secrets/hosts/macbook-pro.pub"
readonly TOPGRADE_CONFIG="${DOTFILES_DIR}/nix/hosts/macbook-pro/users/k0ch4nx/files/topgrade/topgrade.toml"

nix_installer=""
NIX_BIN=""

cleanup() {
  if [[ -n "${nix_installer}" && -e "${nix_installer}" ]]; then
    rm -f -- "${nix_installer}"
  fi
}

die() {
  echo "bootstrap(darwin): $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

find_nix() {
  local candidate

  for candidate in \
    /run/current-system/sw/bin/nix \
    /nix/var/nix/profiles/default/bin/nix \
    "${HOME}/.nix-profile/bin/nix"; do
    if [[ -x "${candidate}" ]]; then
      NIX_BIN="${candidate}"
      return 0
    fi
  done

  return 1
}

nix_cmd() {
  "${NIX_BIN}" --extra-experimental-features "nix-command flakes" "$@"
}

install_nix() {
  if find_nix; then
    log "Using existing Nix: ${NIX_BIN}"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"

  log "Downloading the official Nix installer"
  nix_installer="$(mktemp "${TMPDIR:-/tmp}/nix-installer.XXXXXX")"
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    https://nixos.org/nix/install \
    --output "${nix_installer}"

  log "Installing Nix in multi-user mode"
  if [[ "${MODE}" == "--check" ]]; then
    /bin/sh "${nix_installer}" --daemon --yes
  else
    [[ -r /dev/tty ]] || die "Nix installation requires an interactive terminal for sudo prompts"
    /bin/sh "${nix_installer}" --daemon </dev/tty
  fi

  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  find_nix || die "Nix was installed, but its binary could not be found"
}

prepare_command_line_tools() {
  if /usr/bin/xcode-select --print-path >/dev/null 2>&1; then
    return
  fi

  log "Requesting installation of the Xcode Command Line Tools"
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  die "complete the Command Line Tools installation, then run bootstrap.sh again"
}

clone_or_update_dotfiles() {
  log "Preparing ${DOTFILES_DIR} with Nix-provided Git"

  # The single-quoted script is intentionally expanded only by the Nix-provided Bash.
  # shellcheck disable=SC2016
  nix_cmd shell --inputs-from "github:k0ch4nx/dotfiles?ref=${DOTFILES_REF}" \
    nixpkgs#bash \
    nixpkgs#coreutils \
    nixpkgs#git \
    --command bash -c '
      set -euo pipefail

      repository=$1
      destination=$2
      ref=$3

      if [[ ! -e "${destination}" ]]; then
        mkdir -p "$(dirname "${destination}")"
        git clone --branch "${ref}" --single-branch "${repository}" "${destination}"
        exit
      fi

      [[ -d "${destination}/.git" ]] || {
        echo "bootstrap(darwin): ${destination} exists but is not a Git repository" >&2
        exit 1
      }

      current_ref=$(git -C "${destination}" branch --show-current)
      [[ "${current_ref}" == "${ref}" ]] || {
        echo "bootstrap(darwin): expected branch ${ref}, found ${current_ref}" >&2
        exit 1
      }

      [[ -z "$(git -C "${destination}" status --porcelain)" ]] || {
        echo "bootstrap(darwin): ${destination} has uncommitted changes; refusing to update it" >&2
        exit 1
      }

      origin=$(git -C "${destination}" remote get-url origin)
      case "${origin}" in
        https://github.com/k0ch4nx/dotfiles.git|git@github.com:k0ch4nx/dotfiles.git)
          ;;
        *)
          echo "bootstrap(darwin): unexpected origin URL: ${origin}" >&2
          exit 1
          ;;
      esac

      git -C "${destination}" fetch origin "${ref}"
      git -C "${destination}" merge --ff-only "origin/${ref}"
    ' bootstrap "${DOTFILES_REPOSITORY}" "${DOTFILES_DIR}" "${DOTFILES_REF}"
}

prepare_agenix_keys() {
  log "Preparing YubiKey identity and host key with flake-pinned tools"
  echo "Insert and unlock the YubiKey when prompted."

  # The single-quoted script is intentionally expanded only by the Nix-provided Bash.
  # shellcheck disable=SC2016
  nix_cmd shell --inputs-from "${DOTFILES_DIR}" \
    nixpkgs#age-plugin-yubikey \
    nixpkgs#bash \
    nixpkgs#coreutils \
    nixpkgs#git \
    nixpkgs#rage \
    --command bash -c '
      set -euo pipefail
      umask 077

      repository=$1
      identity=$2
      host_key=$3
      host_public_key=$4
      identity_tmp="${identity}.tmp.$$"
      public_key_tmp="${host_public_key}.tmp.$$"

      cleanup_keys() {
        rm -f -- "${identity_tmp}" "${public_key_tmp}"
      }
      trap cleanup_keys EXIT

      mkdir -p "$(dirname "${identity}")" "$(dirname "${host_key}")"

      if [[ -L "${identity}" && ! -e "${identity}" ]]; then
        rm -f -- "${identity}"
      fi

      if [[ ! -s "${identity}" ]]; then
        age-plugin-yubikey --identity >"${identity_tmp}"
        [[ -s "${identity_tmp}" ]] || {
          echo "bootstrap(darwin): no YubiKey identity was returned" >&2
          exit 1
        }
        chmod 600 "${identity_tmp}"
        mv "${identity_tmp}" "${identity}"
      fi

      if [[ ! -s "${host_key}" ]]; then
        rm -f -- "${host_key}"
        rage-keygen --output "${host_key}"
      fi
      chmod 600 "${host_key}"

      rage-keygen -y "${host_key}" >"${public_key_tmp}"
      if [[ ! -f "${host_public_key}" ]] || ! cmp --silent "${public_key_tmp}" "${host_public_key}"; then
        mv "${public_key_tmp}" "${host_public_key}"
      fi

      git -C "${repository}" add --force "${host_public_key}"
    ' bootstrap "${DOTFILES_DIR}" "${YUBIKEY_IDENTITY}" "${HOST_KEY}" "${HOST_PUBLIC_KEY}"

  log "Rekeying secrets for this host"
  (
    cd "${DOTFILES_DIR}"
    nix_cmd run .#agenix-rekey.aarch64-darwin.rekey
  )
}

apply_darwin_configuration() {
  local darwin_rebuild

  log "Building the flake-pinned darwin-rebuild"
  darwin_rebuild="$(
    nix_cmd build \
      --no-link \
      --print-out-paths \
      "${DOTFILES_DIR}#darwinConfigurations.macbook-pro.config.system.build.darwin-rebuild"
  )"

  log "Applying the nix-darwin configuration"
  # The redirect gives sudo a terminal even when this script is piped from curl.
  # shellcheck disable=SC2024
  sudo "${darwin_rebuild}/bin/darwin-rebuild" switch --flake "${DOTFILES_DIR}#macbook-pro" </dev/tty
}

check_darwin_configuration() {
  local home_path

  log "Evaluating flake checks for all systems"
  nix_cmd flake check "${DOTFILES_DIR}" --no-build --all-systems

  log "Building the macOS system without activating it"
  nix_cmd build \
    --no-link \
    --print-build-logs \
    "${DOTFILES_DIR}#darwinConfigurations.macbook-pro.config.system.build.toplevel"

  log "Evaluating the agenix-rekey derivation"
  nix_cmd eval \
    --raw \
    "${DOTFILES_DIR}#agenix-rekey.aarch64-darwin.rekey.drvPath" \
    >/dev/null

  log "Building the Home Manager environment"
  home_path="$(
    nix_cmd build \
      --no-link \
      --print-out-paths \
      "${DOTFILES_DIR}#darwinConfigurations.macbook-pro.config.home-manager.users.k0ch4nx.home.path"
  )"

  [[ -x "${home_path}/bin/topgrade" ]] || die "Topgrade is missing from the Home Manager environment"
  [[ -f "${TOPGRADE_CONFIG}" ]] || die "Topgrade config not found: ${TOPGRADE_CONFIG}"

  log "Checking the macOS Topgrade configuration"
  "${home_path}/bin/topgrade" --dry-run --config "${TOPGRADE_CONFIG}"
}

run_topgrade() {
  local home_path

  log "Building the Nix-managed Home Manager environment"
  home_path="$(
    nix_cmd build \
      --no-link \
      --print-out-paths \
      "${DOTFILES_DIR}#darwinConfigurations.macbook-pro.config.home-manager.users.k0ch4nx.home.path"
  )"

  [[ -x "${home_path}/bin/topgrade" ]] || die "Topgrade is missing from the Home Manager environment"
  [[ -f "${TOPGRADE_CONFIG}" ]] || die "Topgrade config not found: ${TOPGRADE_CONFIG}"

  export PATH="${home_path}/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${EXPECTED_USER}/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

  log "Running Topgrade with the repository configuration"
  (
    cd "${DOTFILES_DIR}"
    "${home_path}/bin/topgrade" --config "${TOPGRADE_CONFIG}"
  )
}

trap cleanup EXIT

[[ "$(uname -s)" == "Darwin" ]] || die "this script only supports macOS"
[[ "$(uname -m)" == "arm64" ]] || die "this script only supports Apple Silicon Macs"

if [[ "${MODE}" == "--check" ]]; then
  prepare_command_line_tools
  install_nix
  check_darwin_configuration
  log "Darwin bootstrap check completed successfully"
  exit
fi

[[ "$(id -un)" == "${EXPECTED_USER}" ]] || die "run this script as ${EXPECTED_USER}"
[[ "${HOME}" == "/Users/${EXPECTED_USER}" ]] || die "expected HOME=/Users/${EXPECTED_USER}, found ${HOME}"
[[ -r /dev/tty ]] || die "an interactive terminal is required"
exec </dev/tty

prepare_command_line_tools
install_nix
clone_or_update_dotfiles

echo "Ensure that the Mac App Store is signed in before Homebrew activation."
prepare_agenix_keys
apply_darwin_configuration
run_topgrade

log "Bootstrap completed successfully"
