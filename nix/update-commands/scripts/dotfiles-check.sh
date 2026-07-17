shellcheck \
  --external-sources \
  --source-path=SCRIPTDIR \
  "${DOTFILES_DIR}"/bootstrap/*.sh

system="$(nix_command eval --raw --impure --expr builtins.currentSystem)"
case "${system}" in
  aarch64-darwin)
    unsupported='packages: builtins.all (name: builtins.hasAttr name packages == false) [ "apt-upgrade" "home-manager-build" "home-manager-switch" ]'
    ;;
  x86_64-linux)
    unsupported='packages: builtins.all (name: builtins.hasAttr name packages == false) [ "agenix-rekey" "darwin-build" "darwin-ci-secrets" "darwin-switch" "ferium-upgrade" "github-cli-extensions" "homebrew-clean-build-dependencies" "macos-update" "rustup-update" ]'
    ;;
  *)
    printf 'unsupported system: %s\n' "${system}" >&2
    exit 1
    ;;
esac

if [[ "$(nix_command eval --json "${DOTFILES_DIR}#packages.${system}" --apply "${unsupported}")" != "true" ]]; then
  printf 'unsupported update packages are exposed on %s\n' "${system}" >&2
  exit 1
fi

nix_command flake check --no-update-lock-file "${DOTFILES_DIR}"
