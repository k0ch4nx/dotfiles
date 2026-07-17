if ! command -v apt-get >/dev/null 2>&1; then
  printf 'apt-get is not available\n' >&2
  exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is not available\n' >&2
  exit 1
fi

sudo apt-get update
sudo apt-get dist-upgrade
