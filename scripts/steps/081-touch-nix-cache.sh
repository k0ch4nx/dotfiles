#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' &&
    "${NIX_CACHE_TOUCH_WORKER:-}" != '1' ]] && exit 1

function touch_cache() {
    local errors
    local touchlist
    errors="$(mktemp)"
    touchlist="$(mktemp)"
    export TOUCH_ERRORS="${errors}"
    export TOUCH_LIST="${touchlist}"
    trap 'rm -f -- "${TOUCH_ERRORS}" "${TOUCH_LIST}"' EXIT

    local target="${NIX_CACHE_TARGET:-}"
    if [[ -z "${target}" ]]; then
        if [[ "$(uname -s)" == 'Darwin' ]]; then
            target='path:.#configurationBuilds.macbook-pro.system'
        elif [[ -r /proc/sys/kernel/osrelease ]] &&
            grep -qi microsoft /proc/sys/kernel/osrelease; then
            target='path:.#configurationBuilds.ubuntu-wsl.home'
        else
            printf 'Unsupported local platform for cache-touch.\n' >&2
            return 1
        fi
    fi

    local toplevel
    toplevel="$(
        nix build \
            --accept-flake-config \
            --impure \
            --no-link \
            --no-update-lock-file \
            --print-out-paths \
            "${target}"
    )"

    [[ "${toplevel}" =~ ^/nix/store/[0-9a-z]{32}-[^/]+$ ]] || return 1

    local discovery_status=0
    # shellcheck disable=SC2016
    nix path-info --recursive "${toplevel}" \
        | xargs -n1 basename \
        | xargs -P 64 -I{} bash -c '
            name="$1"
            hash="${name%%-*}"
            narinfo=""

            for attempt in 1 2 3; do
                if narinfo="$(
                    aws s3 cp \
                        "s3://${R2_TOUCH_BUCKET}/${hash}.narinfo" \
                        - \
                        2>/dev/null
                )"; then
                    break
                fi
                narinfo=""
                sleep 1
            done

            url="$(
                awk -F ": " '\''$1 == "URL" { print $2; exit }'\'' <<<"${narinfo}"
            )"
            if [[ -z "${url}" ]]; then
                printf "read %s.narinfo\n" "${hash}" >>"${TOUCH_ERRORS}"
                exit 1
            fi

            printf "%s.narinfo\n%s\n" "${hash}" "${url}"
        ' _ {} \
        >"${touchlist}" || discovery_status=$?

    if ((discovery_status != 0)); then
        printf 'Failed to resolve cache objects:\n' >&2
        if [[ -s "${errors}" ]]; then
            cat "${errors}" >&2
        fi
        return 1
    fi

    local total
    total="$(wc -l <"${touchlist}" | tr -d ' ')"
    printf 'Refreshing %s objects...\n' "${total}"

    local refresh_status=0
    # shellcheck disable=SC2016
    xargs -P 64 -I{} bash -c '
        key="$1"

        for attempt in 1 2 3; do
            if head="$(
                aws s3api head-object \
                    --endpoint-url "${AWS_ENDPOINT_URL}" \
                    --bucket "${R2_TOUCH_BUCKET}" \
                    --key "${key}" \
                    2>/dev/null
            )" && request="$(
                jq -c \
                    --arg bucket "${R2_TOUCH_BUCKET}" \
                    --arg key "${key}" \
                    '\''
                        . as $head
                        | {
                            Bucket: $bucket,
                            Key: $key,
                            CopySource: ($bucket + "/" + $key),
                            MetadataDirective: "REPLACE",
                            Metadata: ($head.Metadata // { })
                        } + (
                            $head
                            | {
                                ContentType,
                                CacheControl,
                                ContentDisposition,
                                ContentEncoding,
                                ContentLanguage,
                                Expires,
                                StorageClass
                            }
                            | with_entries(select(.value != null))
                        )
                    '\'' <<<"${head}"
            )" && aws s3api copy-object \
                --endpoint-url "${AWS_ENDPOINT_URL}" \
                --cli-input-json "${request}" \
                >/dev/null 2>&1; then
                exit 0
            fi
            sleep 1
        done

        printf "refresh %s\n" "${key}" >>"${TOUCH_ERRORS}"
        exit 1
    ' _ {} <"${touchlist}" || refresh_status=$?

    if ((refresh_status != 0)); then
        printf 'Failed to refresh cache objects:\n' >&2
        if [[ -s "${errors}" ]]; then
            cat "${errors}" >&2
        fi
        return 1
    fi

    printf 'Refreshed %s objects.\n' "${total}"
}

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

    NIX_CACHE_TOUCH_WORKER=1 \
        nix shell \
        'nixpkgs#awscli2' \
        'nixpkgs#jq' \
        --accept-flake-config \
        -c bash -- "${BASH_SOURCE[0]}"
)

if [[ "${NIX_CACHE_TOUCH_WORKER:-}" == '1' ]]; then
    touch_cache
else
    main
fi
