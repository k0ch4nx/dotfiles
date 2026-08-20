#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' &&
    "${NIX_CACHE_TOUCH_WORKER:-}" != '1' ]] && exit 1

R2_TOUCH_SCRIPT_PATH="${BASH_SOURCE[0]}"

function touch_cache() (
    set +x

    local errors
    local touchlist
    local closure_file=''
    local remove_closure_file='false'
    errors="$(mktemp)"
    touchlist="$(mktemp)"
    export TOUCH_ERRORS="${errors}"
    export TOUCH_LIST="${touchlist}"
    trap 'rm -f -- "${TOUCH_ERRORS}" "${TOUCH_LIST}"; [[ "${remove_closure_file}" != "true" || -z "${closure_file}" ]] || rm -f -- "${closure_file}"' EXIT

    if [[ -n "${NIX_CACHE_CLOSURE_FILE:-}" ]]; then
        closure_file="${NIX_CACHE_CLOSURE_FILE}"
        if [[ ! -r "${closure_file}" ]]; then
            printf 'Nix cache closure manifest is not readable: %s\n' "${closure_file}" >&2
            return 1
        fi
    else
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

        closure_file="$(mktemp)"
        remove_closure_file='true'
        nix path-info --recursive "${toplevel}" >"${closure_file}"
    fi

    local discovery_status=0
    # shellcheck disable=SC2016
    tr '\n' '\000' <"${closure_file}" \
        | xargs -0 -n 32 -P 32 bash -c '
        status=0
        for store_path; do
            name="${store_path##*/}"
            hash="${name%%-*}"
            narinfo=""

            if [[ ! "${hash}" =~ ^[0-9a-z]{32}$ ]]; then
                printf "read invalid store path: %s\n" "${store_path}" >>"${TOUCH_ERRORS}"
                status=1
                continue
            fi

            for attempt in 1 2 3; do
                if narinfo="$(
                    aws s3 cp \
                        --endpoint-url "${AWS_ENDPOINT_URL}" \
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
                status=1
                continue
            fi

            printf "%s.narinfo\n%s\n" "${hash}" "${url}"
        done
        exit "${status}"
    ' _ \
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
    tr '\n' '\000' <"${touchlist}" \
        | xargs -0 -n 32 -P 32 bash -c '
        status=0
        for key; do
            refreshed=false

            for attempt in 1 2 3; do
                # R2 MERGE retains source standard and custom metadata.
                if aws s3api copy-object \
                --endpoint-url "${AWS_ENDPOINT_URL}" \
                --bucket "${R2_TOUCH_BUCKET}" \
                --key "${key}" \
                --copy-source "${R2_TOUCH_BUCKET}/${key}" \
                --metadata-directive MERGE \
                --metadata "nix-cache-touch=${R2_TOUCH_ID}" \
                >/dev/null 2>&1; then
                    refreshed=true
                    break
                fi
                sleep 1
            done

            if [[ "${refreshed}" != true ]]; then
                printf "refresh %s\n" "${key}" >>"${TOUCH_ERRORS}"
                status=1
            fi
        done
        exit "${status}"
    ' _ || refresh_status=$?

    if ((refresh_status != 0)); then
        printf 'Failed to refresh cache objects:\n' >&2
        if [[ -s "${errors}" ]]; then
            cat "${errors}" >&2
        fi
        return 1
    fi

    printf 'Refreshed %s objects.\n' "${total}"
)

function main() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    cd -- "${DOTFILES_DIR}"

    # shellcheck disable=SC1091
    source "${DOTFILES_DIR}/scripts/lib/r2-terraform-outputs.sh"

    local r2_values
    r2_values="$(read_r2_terraform_outputs rw)"

    local bucket
    local s3_endpoint
    local access_key_id
    local secret_access_key
    IFS=$'\t' read -r \
        bucket \
        s3_endpoint \
        access_key_id \
        secret_access_key \
        <<<"${r2_values}"

    export AWS_ACCESS_KEY_ID="${access_key_id}"
    export AWS_SECRET_ACCESS_KEY="${secret_access_key}"
    export AWS_ENDPOINT_URL="${s3_endpoint}"
    export R2_TOUCH_BUCKET="${bucket}"

    local touch_id="${R2_TOUCH_ID:-}"
    if [[ -z "${touch_id}" ]]; then
        touch_id="$(date -u +%Y%m%dT%H%M%SZ)-$$-${RANDOM}${RANDOM}"
    fi
    if [[ ! "${touch_id}" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$ ]]; then
        printf 'R2_TOUCH_ID must contain 1-128 letters, numbers, periods, colons, underscores, or hyphens.\n' >&2
        return 1
    fi
    export R2_TOUCH_ID="${touch_id}"

    NIX_CACHE_TOUCH_WORKER=1 \
        nix shell \
        'nixpkgs#awscli2' \
        --accept-flake-config \
        -c bash -- "${R2_TOUCH_SCRIPT_PATH}"
)

if [[ "${NIX_CACHE_TOUCH_WORKER:-}" == '1' ]]; then
    touch_cache
else
    main
fi
