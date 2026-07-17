: "${DOTFILES_HOST:?DOTFILES_HOST is required}"

nix_command build \
  --no-update-lock-file \
  --no-link \
  "${DOTFILES_DIR}#darwinConfigurations.${DOTFILES_HOST}.config.system.build.toplevel"
