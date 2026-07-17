: "${DOTFILES_HOST:?DOTFILES_HOST is required}"

if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is not available\n' >&2
  exit 1
fi

printf 'Ensure that the Mac App Store is signed in before Homebrew activation.\n'
darwin_rebuild="$(
  nix_command build \
    --no-update-lock-file \
    --no-link \
    --print-out-paths \
    "${DOTFILES_DIR}#darwinConfigurations.${DOTFILES_HOST}.config.system.build.darwin-rebuild"
)"

cd "${DOTFILES_DIR}" || exit
sudo "${darwin_rebuild}/bin/darwin-rebuild" switch \
  --no-update-lock-file \
  --flake ".#${DOTFILES_HOST}"
