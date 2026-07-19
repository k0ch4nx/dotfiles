#!/usr/bin/env bash

set -euo pipefail

readonly profile="nix-cache"

if [[ "$(uname -s)" == "Darwin" ]]; then
    root_aws_dir="/var/root/.aws"
else
    root_aws_dir="/root/.aws"
fi

credentials="$(mktemp "${RUNNER_TEMP%/}/r2-credentials.XXXXXX")"

umask 077

printf '[%s]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
    "${profile}" \
    "${R2_ACCESS_KEY_ID}" \
    "${R2_SECRET_ACCESS_KEY}" >"${credentials}"

if ((EUID == 0)); then
    install -d -m 700 "${root_aws_dir}"
    install -m 600 "${credentials}" "${root_aws_dir}/credentials"
else
    sudo install -d -m 700 "${root_aws_dir}"
    sudo install -m 600 "${credentials}" "${root_aws_dir}/credentials"
fi

cache="s3://${R2_CACHE_BUCKET}?endpoint=${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=${profile}"

nix_config="${NIX_CONFIG:-}"

if [[ -n "${nix_config}" ]]; then
    nix_config+=$'\n'
fi

nix_config+="extra-substituters = ${cache}"$'\n'
nix_config+="extra-trusted-public-keys = ${NIX_CACHE_LOCAL_PUBLIC_KEY} ${NIX_CACHE_CI_PUBLIC_KEY}"$'\n'
nix_config+="fallback = true"

if [[ -n "${GITHUB_ENV:-}" ]]; then
    delimiter="NIX_CONFIG_${RANDOM}_$$"

    {
        printf 'NIX_CONFIG<<%s\n' "${delimiter}"
        printf '%s\n' "${nix_config}"
        printf '%s\n' "${delimiter}"
        printf 'R2_CREDENTIALS_FILE=%s\n' "${credentials}"
        printf 'AWS_SHARED_CREDENTIALS_FILE=%s\n' "${credentials}"
    } >>"${GITHUB_ENV}"
else
    printf 'export NIX_CONFIG=%q\n' "${nix_config}"
    printf 'export R2_CREDENTIALS_FILE=%q\n' "${credentials}"
    printf 'export AWS_SHARED_CREDENTIALS_FILE=%q\n' "${credentials}"
fi
