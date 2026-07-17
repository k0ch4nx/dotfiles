: "${DOTFILES_HOST:?DOTFILES_HOST is required}"

identity="${HOME}/.config/age/yubikey-identity.txt"
identity_tmp=""

cleanup_identity() {
  if [[ -n "${identity_tmp}" && -e "${identity_tmp}" ]]; then
    rm -f -- "${identity_tmp}"
  fi
}
trap cleanup_identity EXIT

if [[ -L "${identity}" && ! -e "${identity}" ]]; then
  rm -f -- "${identity}"
fi
if [[ ! -s "${identity}" ]]; then
  printf 'Insert and unlock the YubiKey when prompted.\n'
  mkdir -p "$(dirname "${identity}")"
  identity_tmp="${identity}.tmp.$$"
  if ! (umask 077; age-plugin-yubikey --identity >"${identity_tmp}"); then
    printf 'failed to read the YubiKey identity\n' >&2
    exit 1
  fi
  if [[ ! -s "${identity_tmp}" ]]; then
    printf 'no YubiKey identity was returned\n' >&2
    exit 1
  fi
  chmod 600 "${identity_tmp}"
  mv "${identity_tmp}" "${identity}"
  identity_tmp=""
fi

host_key="${DOTFILES_DIR}/secrets/hosts/${DOTFILES_HOST}-key.txt"
host_public_key="${DOTFILES_DIR}/secrets/hosts/${DOTFILES_HOST}.pub"
if [[ ! -f "${host_key}" ]]; then
  mkdir -p "$(dirname "${host_key}")"
  rage-keygen -o "${host_key}"
fi
chmod 600 "${host_key}"
rage-keygen -y "${host_key}" >"${host_public_key}"
git -C "${DOTFILES_DIR}" add -f "${host_public_key}"

system="$(nix_command eval --raw --impure --expr builtins.currentSystem)"
cd "${DOTFILES_DIR}" || exit
nix_command run \
  --no-update-lock-file \
  "${DOTFILES_DIR}#agenix-rekey.${system}.rekey"
