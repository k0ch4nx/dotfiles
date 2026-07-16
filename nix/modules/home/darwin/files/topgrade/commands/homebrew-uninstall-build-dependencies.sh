#!/usr/bin/env bash

set -euo pipefail

leaves=($(brew leaves --installed-as-dependency | xargs))
for pkg in "${leaves[@]}"; do
  brew uninstall "$pkg"
done
