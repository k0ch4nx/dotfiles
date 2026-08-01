#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' ]] && exit 1

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    function read_credential() {
        local file="$1"
        local label="$2"
        local value

        if [[ ! -r "${file}" ]]; then
            printf '%s is not readable: %s\n' "${label}" "${file}" >&2
            return 1
        fi

        value="$(<"${file}")"

        if [[ -z "${value}" ]] || [[ "${value}" == *$'\n'* ]]; then
            printf '%s must contain exactly one non-empty value.\n' "${label}" >&2
            return 1
        fi

        printf '%s' "${value}"
    }

    local bucket
    bucket="${R2_CACHE_BUCKET:-$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            'path:.#cacheSettings.bucket'
    )}"

    local account_id
    account_id="${CLOUDFLARE_ACCOUNT_ID:-$(
        nix eval \
            --accept-flake-config \
            --impure \
            --no-update-lock-file \
            --raw \
            'path:.#cacheSettings.accountId'
    )}"

    local config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local access_key_id="${R2_ACCESS_KEY_ID:-}"
    local secret_access_key="${R2_SECRET_ACCESS_KEY:-}"

    if [[ -n "${access_key_id}" && -z "${secret_access_key}" ]] ||
        [[ -z "${access_key_id}" && -n "${secret_access_key}" ]]; then
        printf 'R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY must be provided together.\n' >&2
        return 1
    fi

    if [[ -z "${access_key_id}" ]]; then
        access_key_id="$(read_credential "${config_home}/nix-cache/access-key-id" 'R2 access key ID')"
        secret_access_key="$(read_credential "${config_home}/nix-cache/secret-access-key" 'R2 secret access key')"
    fi

    export AWS_ACCESS_KEY_ID="${access_key_id}"
    export AWS_SECRET_ACCESS_KEY="${secret_access_key}"
    export AWS_ENDPOINT_URL="https://${account_id}.r2.cloudflarestorage.com"
    export R2_TOUCH_BUCKET="${bucket}"

    nix shell 'nixpkgs#awscli2' --accept-flake-config -c bash -s <<'SCRIPT'
set -euo pipefail

errors="$(mktemp)"
touchlist="$(mktemp)"
trap 'rm -f "${errors}" "${touchlist}"' EXIT
export TOUCH_ERRORS="${errors}"

target="${NIX_CACHE_TARGET:-}"
if [[ -z "${target}" ]]; then
    if [[ "$(uname -s)" == 'Darwin' ]]; then
        target='path:.#configurationBuilds.macbook-pro.system'
    elif [[ -r /proc/sys/kernel/osrelease ]] &&
        grep -qi microsoft /proc/sys/kernel/osrelease; then
        target='path:.#configurationBuilds.ubuntu-wsl.home'
    else
        printf 'Unsupported local platform for cache-touch.\n' >&2
        exit 1
    fi
fi

toplevel="$(
    nix build \
        --accept-flake-config \
        --impure \
        --no-link \
        --no-update-lock-file \
        --print-out-paths \
        "${target}"
)"

[[ "${toplevel}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || exit 1

nix path-info --recursive "${toplevel}" \
    | xargs -n1 basename \
    | xargs -P 64 -I{} sh -c '
        name="$1"
        hash="${name%%-*}"
        url="$(
            aws s3 cp "s3://${R2_TOUCH_BUCKET}/${hash}.narinfo" - 2>/dev/null \
                | grep "^URL:" | cut -d" " -f2
        )"
        if [[ -n "${url}" ]]; then
            printf "%s.narinfo\n%s\n" "${hash}" "${url}"
        fi
    ' _ {} \
    >"${touchlist}" || true

total="$(wc -l <"${touchlist}" | tr -d ' ')"
printf 'Refreshing %s objects...\n' "${total}"

xargs -P 64 -I{} sh -c '
    for attempt in 1 2 3; do
        if aws s3api copy-object \
            --endpoint-url "${AWS_ENDPOINT_URL}" \
            --bucket "${R2_TOUCH_BUCKET}" \
            --key "$1" \
            --copy-source "${R2_TOUCH_BUCKET}/$1" \
            --metadata-directive REPLACE \
            >/dev/null 2>&1; then
            exit 0
        fi
        sleep 1
    done
    printf '%s\n' "$1" >>"${TOUCH_ERRORS}"
    exit 1
' _ {} <"${touchlist}" || true

if [[ -s "${errors}" ]]; then
    printf 'Failed to refresh %s objects:\n' "$(wc -l <"${errors}" | tr -d ' ')" >&2
    cat "${errors}" >&2
    exit 1
fi

printf 'Refreshed %s objects.\n' "${total}"
SCRIPT
)

main
