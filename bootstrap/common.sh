#!/usr/bin/env bash

readonly DOTFILES_REMOTE="github.com"
readonly DOTFILES_USER="${EXPECTED_USER}"
readonly DOTFILES_REPO="dotfiles"
readonly DOTFILES_REPOSITORY="https://${DOTFILES_REMOTE}/${DOTFILES_USER}/${DOTFILES_REPO}.git"
readonly DOTFILES_SSH_REPOSITORY="git@${DOTFILES_REMOTE}:${DOTFILES_USER}/${DOTFILES_REPO}.git"
readonly TOPGRADE_CONFIG="${HOME}/.config/topgrade/topgrade.toml"

nix_installer=""
NIX_BIN=""

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

      [[ -z "$(git -C "${destination}" status --porcelain)" ]] || {
        echo "bootstrap(${bootstrap_name}): ${destination} has uncommitted changes; refusing to update it" >&2
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

      git -C "${destination}" fetch origin "${ref}"
      git -C "${destination}" merge --ff-only "origin/${ref}"
    ' bootstrap \
    "${DOTFILES_REPOSITORY}" \
    "${DOTFILES_DIR}" \
    "${DOTFILES_REF}" \
    "${DOTFILES_SSH_REPOSITORY}" \
    "${BOOTSTRAP_NAME}"
}

build_flake_path() {
  local attribute=$1

  nix_cmd build \
    --no-update-lock-file \
    --no-link \
    --print-out-paths \
    "${DOTFILES_DIR}#${attribute}"
}

check_flake() {
  log "Checking flake outputs"
  nix_cmd flake check \
    --no-update-lock-file \
    "${DOTFILES_DIR}"
}

ensure_bootstrap_link() {
  local destination=$1
  local source=$2

  [[ -e "${source}" ]] || die "Topgrade source not found: ${source}"

  if [[ -e "${destination}" && "${destination}" -ef "${source}" ]]; then
    return
  fi

  if [[ -e "${destination}" || -L "${destination}" ]]; then
    die "refusing to replace existing Topgrade path: ${destination}"
  fi

  mkdir -p "$(dirname "${destination}")"
  ln -s "${source}" "${destination}"
}

prepare_topgrade_config() {
  local host_topgrade_dir=$1
  local common_topgrade_dir="${DOTFILES_DIR}/nix/home/${EXPECTED_USER}/files/topgrade"
  local topgrade_dir="${HOME}/.config/topgrade"

  if [[ "${TOPGRADE_CONFIG}" -ef "${host_topgrade_dir}/topgrade.toml" \
    && "${topgrade_dir}/commands/common" -ef "${common_topgrade_dir}/commands" \
    && "${topgrade_dir}/commands/host" -ef "${host_topgrade_dir}/commands" \
    && "${topgrade_dir}/includes/common" -ef "${common_topgrade_dir}/includes" \
    && "${topgrade_dir}/includes/host" -ef "${host_topgrade_dir}/includes" ]]; then
    log "Using existing Topgrade configuration"
    return
  fi

  log "Preparing the initial Topgrade configuration"
  ensure_bootstrap_link "${TOPGRADE_CONFIG}" "${host_topgrade_dir}/topgrade.toml"
  ensure_bootstrap_link "${topgrade_dir}/commands/common" "${common_topgrade_dir}/commands"
  ensure_bootstrap_link "${topgrade_dir}/commands/host" "${host_topgrade_dir}/commands"
  ensure_bootstrap_link "${topgrade_dir}/includes/common" "${common_topgrade_dir}/includes"
  ensure_bootstrap_link "${topgrade_dir}/includes/host" "${host_topgrade_dir}/includes"
}

run_topgrade() {
  local home_path=$1
  local extra_path=$2
  local host_topgrade_dir=$3
  local topgrade_path="${home_path}/bin/topgrade"
  local runtime_path="${home_path}/bin:${NIX_BIN%/nix}:${PATH}"

  [[ -x "${topgrade_path}" ]] || die "Topgrade is missing from the Home Manager environment"
  if [[ -n "${extra_path}" ]]; then
    runtime_path="${extra_path}:${runtime_path}"
  fi

  prepare_topgrade_config "${host_topgrade_dir}"
  [[ -f "${TOPGRADE_CONFIG}" ]] || die "Topgrade config not found: ${TOPGRADE_CONFIG}"

  log "Running Topgrade with the repository configuration"
  (
    cd "${DOTFILES_DIR}"
    export BOOTSTRAP_NO_FLAKE_UPDATE=1
    export DOTFILES_DIR
    export PATH="${runtime_path}"
    "${topgrade_path}" --config "${TOPGRADE_CONFIG}"
  )
}
