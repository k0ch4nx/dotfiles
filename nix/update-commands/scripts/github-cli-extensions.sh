if [[ -z "$(gh extension list)" ]]; then
  printf 'No GitHub CLI extensions are installed; skipping.\n'
  exit 0
fi

gh extension upgrade --all
