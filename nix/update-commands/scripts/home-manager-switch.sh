: "${DOTFILES_HOST:?DOTFILES_HOST is required}"

attribute="homeConfigurations.\"${DOTFILES_HOST}\".activationPackage"
activation_package="$(
  nix_command build \
    --no-update-lock-file \
    --no-link \
    --print-out-paths \
    "${DOTFILES_DIR}#${attribute}"
)"

if [[ ! -x "${activation_package}/activate" ]]; then
  printf 'Home Manager activation script is missing: %s\n' "${activation_package}/activate" >&2
  exit 1
fi

"${activation_package}/activate"
