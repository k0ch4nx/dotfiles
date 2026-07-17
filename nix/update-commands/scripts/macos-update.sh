if [[ ! -x /usr/sbin/softwareupdate ]]; then
  printf 'softwareupdate is not available\n' >&2
  exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is not available\n' >&2
  exit 1
fi

sudo /usr/sbin/softwareupdate --install --all
