: "${DOTFILES_HOST:?DOTFILES_HOST is required}"

system="$(nix_command eval --raw --impure --expr builtins.currentSystem)"
cd "${DOTFILES_DIR}" || exit
nix_command run \
  --no-update-lock-file \
  "${DOTFILES_DIR}#agenix-rekey.${system}.rekey" \
  -- --dummy

untracked_secrets="$(git -C "${DOTFILES_DIR}" ls-files --others --exclude-standard -- secrets)"
if [[ -n "${untracked_secrets}" ]]; then
  printf 'darwin-ci-secrets created untracked files:\n%s\n' "${untracked_secrets}" >&2
  exit 1
fi
