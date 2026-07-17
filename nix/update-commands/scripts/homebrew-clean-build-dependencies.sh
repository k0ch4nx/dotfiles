brew_bin="$(command -v brew || true)"
if [[ -z "${brew_bin}" ]]; then
  printf 'brew is not available\n' >&2
  exit 1
fi

while IFS= read -r package; do
  if [[ -n "${package}" ]]; then
    "${brew_bin}" uninstall "${package}"
  fi
done < <("${brew_bin}" leaves --installed-as-dependency)
