: "${DOTFILES_DIR:?DOTFILES_DIR is required}"

if [[ ! -f "${DOTFILES_DIR}/flake.nix" ]]; then
  printf 'flake.nix not found: %s\n' "${DOTFILES_DIR}" >&2
  exit 1
fi

dotfiles_root="$(cd "${DOTFILES_DIR}" && pwd -P)"
git_root="$(git -C "${DOTFILES_DIR}" rev-parse --show-toplevel)"
if [[ "${git_root}" != "${dotfiles_root}" ]]; then
  printf 'DOTFILES_DIR is not the Git worktree root: %s\n' "${DOTFILES_DIR}" >&2
  exit 1
fi

origin="$(git -C "${DOTFILES_DIR}" remote get-url origin)"
case "${origin}" in
  "https://github.com/k0ch4nx/dotfiles.git"|"git@github.com:k0ch4nx/dotfiles.git")
    ;;
  *)
    printf 'unexpected dotfiles origin: %s\n' "${origin}" >&2
    exit 1
    ;;
esac

readonly dotfiles_root git_root origin

nix_command() {
  nix --extra-experimental-features "nix-command flakes" "$@"
}
