#!/usr/bin/env bash

readonly DOTFILES_REMOTE="github.com"
readonly DOTFILES_USER="${EXPECTED_USER}"
readonly DOTFILES_REPO="dotfiles"
readonly DOTFILES_REPOSITORY="https://${DOTFILES_REMOTE}/${DOTFILES_USER}/${DOTFILES_REPO}.git"
readonly DOTFILES_SSH_REPOSITORY="git@${DOTFILES_REMOTE}:${DOTFILES_USER}/${DOTFILES_REPO}.git"

nix_installer=""
NIX_BIN=""
FAILED_COMMANDS=()

is_ci() {
  [[ -n "${CI+x}" ]]
}

cleanup() {
  if [[ -n "${nix_installer}" && -e "${nix_installer}" ]]; then
    rm -f -- "${nix_installer}"
  fi
  if [[ -n "${bootstrap_common:-}" && -e "${bootstrap_common}" ]]; then
    rm -f -- "${bootstrap_common}"
  fi
}

die() {
  echo "bootstrap(${BOOTSTRAP_NAME}): $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

find_nix() {
  local candidate

  candidate="$(command -v nix 2>/dev/null || true)"
  if [[ -n "${candidate}" && -x "${candidate}" ]]; then
    NIX_BIN="${candidate}"
    return 0
  fi

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
  local install_mode=$1
  local profile_script=$2
  local install_description
  local -a installer_args

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

  installer_args=("${install_mode}")
  if [[ "${install_mode}" == "--daemon" ]]; then
    install_description="multi-user"
  else
    install_description="single-user"
  fi

  log "Installing Nix in ${install_description} mode"
  if is_ci; then
    installer_args+=(--yes)
    /bin/sh "${nix_installer}" "${installer_args[@]}"
  else
    [[ -r /dev/tty ]] || die "Nix installation requires an interactive terminal"
    /bin/sh "${nix_installer}" "${installer_args[@]}" </dev/tty
  fi

  if [[ -r "${profile_script}" ]]; then
    # shellcheck disable=SC1090
    source "${profile_script}"
  fi

  find_nix || die "Nix was installed, but its binary could not be found"
}

clone_or_update_dotfiles() {
  log "Preparing ${DOTFILES_DIR} with Nix-provided Git"

  # The single-quoted script is intentionally expanded only by the Nix-provided Bash.
  # shellcheck disable=SC2016
  # DOTFILES_REF is defined by each platform entrypoint before this file is sourced.
  # shellcheck disable=SC2153
  nix_cmd shell --no-update-lock-file \
    --inputs-from "github:${DOTFILES_USER}/${DOTFILES_REPO}?ref=${DOTFILES_REF}" \
    nixpkgs#bash \
    nixpkgs#coreutils \
    nixpkgs#git \
    --command bash -c '
      set -euo pipefail

      repository=$1
      destination=$2
      ref=$3
      ssh_repository=$4
      bootstrap_name=$5

      if [[ ! -e "${destination}" ]]; then
        mkdir -p "$(dirname "${destination}")"
        git clone --branch "${ref}" --single-branch "${repository}" "${destination}"
        exit
      fi

      [[ -d "${destination}/.git" ]] || {
        echo "bootstrap(${bootstrap_name}): ${destination} exists but is not a Git repository" >&2
        exit 1
      }

      current_ref=$(git -C "${destination}" branch --show-current)
      [[ "${current_ref}" == "${ref}" ]] || {
        echo "bootstrap(${bootstrap_name}): expected branch ${ref}, found ${current_ref}" >&2
        exit 1
      }

      origin=$(git -C "${destination}" remote get-url origin)
      case "${origin}" in
        "${repository}"|"${ssh_repository}")
          ;;
        *)
          echo "bootstrap(${bootstrap_name}): unexpected origin URL: ${origin}" >&2
          exit 1
          ;;
      esac

      if [[ -n "$(git -C "${destination}" status --porcelain)" ]]; then
        echo "bootstrap(${bootstrap_name}): ${destination} has local changes; skipping the remote update"
        exit
      fi

      git -C "${destination}" fetch origin "${ref}"
      git -C "${destination}" merge --ff-only "origin/${ref}"
    ' bootstrap \
    "${DOTFILES_REPOSITORY}" \
    "${DOTFILES_DIR}" \
    "${DOTFILES_REF}" \
    "${DOTFILES_SSH_REPOSITORY}" \
    "${BOOTSTRAP_NAME}"
}

run_flake_command() {
  local package=$1

  [[ "${package}" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid update package name: ${package}"
  case "${package}" in
    agenix-rekey|apt-upgrade|darwin-build|darwin-ci-secrets|darwin-switch|dotfiles-check|ferium-upgrade|github-cli-extensions|home-manager-build|home-manager-switch|homebrew-clean-build-dependencies|macos-update|neovim-codediff|neovim-lazy|neovim-mason|neovim-treesitter|nix-update|rustup-update)
      ;;
    *)
      die "update package is not allowed: ${package}"
      ;;
  esac

  log "Running ${package}"
  nix_cmd run \
    --no-update-lock-file \
    "${DOTFILES_DIR}#${package}"
}

run_optional_flake_command() {
  local package=$1

  if run_flake_command "${package}"; then
    return
  fi

  FAILED_COMMANDS+=("${package}")
  echo "bootstrap(${BOOTSTRAP_NAME}): ${package} failed; continuing" >&2
}

finish_optional_flake_commands() {
  local package

  if [[ ${#FAILED_COMMANDS[@]} -eq 0 ]]; then
    return
  fi

  echo "bootstrap(${BOOTSTRAP_NAME}): update commands failed:" >&2
  for package in "${FAILED_COMMANDS[@]}"; do
    echo "  - ${package}" >&2
  done
  return 1
}
