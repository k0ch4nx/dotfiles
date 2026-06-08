#!/usr/bin/env sh

set -euxo pipefail

sudo apt-get update
sudo apt-get --yes upgrade
sudo apt-get --yes install extrepo

sudo extrepo enable mise

sudo apt-get --yes install \
    mise \
    unzip \
    zsh

curl -fsSL https://bun.com/install | bash
curl -s https://ohmyposh.dev/install.sh | bash -s
curl -fsSL https://opencode.ai/install | bash
