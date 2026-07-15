#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "usage: wsl.sh [--check]" >&2
  exit 2
fi

readonly MODE="${1:-apply}"
readonly EXPECTED_USER="k0ch4nx"
readonly DOTFILES_REF="${DOTFILES_REF:-main}"
readonly GHQ_ROOT="${HOME}/src"
readonly DOTFILES_REMOTE="github.com"
readonly DOTFILES_USER="${EXPECTED_USER}"
readonly DOTFILES_REPO="dotfiles"
readonly DOTFILES_REPOSITORY="https://${DOTFILES_REMOTE}/${DOTFILES_USER}/${DOTFILES_REPO}.git"
readonly DOTFILES_SSH_REPOSITORY="git@${DOTFILES_REMOTE}:${DOTFILES_USER}/${DOTFILES_REPO}.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
DOTFILES_DIR=""

if [[ "${MODE}" == "--check" ]]; then
  DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
elif [[ "${MODE}" == "apply" ]]; then
  DOTFILES_DIR="${GHQ_ROOT}/${DOTFILES_REMOTE}/${DOTFILES_USER}/${DOTFILES_REPO}"
else
  echo "usage: wsl.sh [--check]" >&2
  exit 2
fi
readonly DOTFILES_DIR

readonly TOPGRADE_CONFIG="${HOME}/.config/topgrade/topgrade.toml"

nix_installer=""
NIX_BIN=""

cleanup() {
  if [[ -n "${nix_installer}" && -e "${nix_installer}" ]]; then
    rm -f -- "${nix_installer}"
  fi
}

die() {
  echo "bootstrap(wsl): $*" >&2
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

  log "Installing Nix in single-user mode"
  if [[ "${MODE}" == "--check" ]]; then
    /bin/sh "${nix_installer}" --no-daemon --yes
  else
    [[ -r /dev/tty ]] || die "Nix installation requires an interactive terminal"
    /bin/sh "${nix_installer}" --no-daemon </dev/tty
  fi

  find_nix || die "Nix was installed, but its binary could not be found"
}

clone_or_update_dotfiles() {
  log "Preparing ${DOTFILES_DIR} with Nix-provided Git"

  # The single-quoted script is intentionally expanded only by the Nix-provided Bash.
  # shellcheck disable=SC2016
  nix_cmd shell --inputs-from "github:${DOTFILES_USER}/${DOTFILES_REPO}?ref=${DOTFILES_REF}" \
    nixpkgs#bash \
    nixpkgs#coreutils \
    nixpkgs#git \
    --command bash -c '
      set -euo pipefail

      repository=$1
      destination=$2
      ref=$3
      ssh_repository=$4

      if [[ ! -e "${destination}" ]]; then
        mkdir -p "$(dirname "${destination}")"
        git clone --branch "${ref}" --single-branch "${repository}" "${destination}"
        exit
      fi

      [[ -d "${destination}/.git" ]] || {
        echo "bootstrap(wsl): ${destination} exists but is not a Git repository" >&2
        exit 1
      }

      current_ref=$(git -C "${destination}" branch --show-current)
      [[ "${current_ref}" == "${ref}" ]] || {
        echo "bootstrap(wsl): expected branch ${ref}, found ${current_ref}" >&2
        exit 1
      }

      [[ -z "$(git -C "${destination}" status --porcelain)" ]] || {
        echo "bootstrap(wsl): ${destination} has uncommitted changes; refusing to update it" >&2
        exit 1
      }

      origin=$(git -C "${destination}" remote get-url origin)
      case "${origin}" in
        "${repository}"|"${ssh_repository}")
          ;;
        *)
          echo "bootstrap(wsl): unexpected origin URL: ${origin}" >&2
          exit 1
          ;;
      esac

      git -C "${destination}" fetch origin "${ref}"
      git -C "${destination}" merge --ff-only "origin/${ref}"
    ' bootstrap "${DOTFILES_REPOSITORY}" "${DOTFILES_DIR}" "${DOTFILES_REF}" "${DOTFILES_SSH_REPOSITORY}"
}

build_activation_package() {
  nix_cmd build \
    --no-link \
    --print-out-paths \
    "${DOTFILES_DIR}#homeConfigurations.\"k0ch4nx@ubuntu-wsl\".activationPackage"
}

build_home_path() {
  nix_cmd build \
    --no-link \
    --print-out-paths \
    "${DOTFILES_DIR}#homeConfigurations.\"k0ch4nx@ubuntu-wsl\".config.home.path"
}

check_wsl_configuration() {
  local activation_package
  local home_path
  local topgrade_home
  local topgrade_config

  log "Building the WSL Home Manager activation package"
  activation_package="$(build_activation_package)"
  [[ -x "${activation_package}/activate" ]] || die "Home Manager activation script is missing"
  topgrade_home="${activation_package}/home-files"
  topgrade_config="${topgrade_home}/.config/topgrade/topgrade.toml"
  [[ -f "${topgrade_config}" ]] || die "Topgrade config not found in the Home Manager generation"

  log "Building the WSL Home Manager environment"
  home_path="$(build_home_path)"
  [[ -x "${home_path}/bin/topgrade" ]] || die "Topgrade is missing from the Home Manager environment"

  log "Checking the WSL Topgrade configuration"
  HOME="${topgrade_home}" \
    XDG_CONFIG_HOME="${topgrade_home}/.config" \
    "${home_path}/bin/topgrade" --dry-run --config "${topgrade_config}"
}

apply_home_configuration() {
  local activation_package

  log "Building the WSL Home Manager activation package"
  activation_package="$(build_activation_package)"

  log "Applying the WSL Home Manager configuration"
  "${activation_package}/activate"
}

run_topgrade() {
  local home_path

  log "Building the Nix-managed Home Manager environment"
  home_path="$(build_home_path)"

  [[ -x "${home_path}/bin/topgrade" ]] || die "Topgrade is missing from the Home Manager environment"
  [[ -f "${TOPGRADE_CONFIG}" ]] || die "Topgrade config not found: ${TOPGRADE_CONFIG}"

  export PATH="${home_path}/bin:${NIX_BIN%/nix}:${PATH}"

  log "Running Topgrade with the WSL configuration"
  (
    cd "${DOTFILES_DIR}"
    "${home_path}/bin/topgrade" --config "${TOPGRADE_CONFIG}"
  )
}

trap cleanup EXIT

[[ "$(uname -s)" == "Linux" ]] || die "this script only supports Linux under WSL"
[[ -r /proc/sys/kernel/osrelease ]] || die "cannot identify the WSL kernel"
grep -qi microsoft /proc/sys/kernel/osrelease || die "this script only supports WSL"

if [[ "${MODE}" == "--check" ]]; then
  install_nix
  check_wsl_configuration
  log "WSL bootstrap check completed successfully"
  exit
fi

[[ "$(id -un)" == "${EXPECTED_USER}" ]] || die "run this script as ${EXPECTED_USER}"
[[ "${HOME}" == "/home/${EXPECTED_USER}" ]] || die "expected HOME=/home/${EXPECTED_USER}, found ${HOME}"
[[ -r /dev/tty ]] || die "an interactive terminal is required"
exec </dev/tty

install_nix
clone_or_update_dotfiles
apply_home_configuration
run_topgrade

log "Bootstrap completed successfully"
