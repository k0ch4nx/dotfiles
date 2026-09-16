#!/usr/bin/env bash

set -euo pipefail

[[ "${BASH_SOURCE[0]}" == "$0" && "${GITHUB_ACTIONS:-}" != 'true' &&
    "${NIX_CACHE_TOUCH_WORKER:-}" != '1' ]] && exit 1

R2_TOUCH_SCRIPT_PATH="${BASH_SOURCE[0]}"

function touch_scope() {
    if [[ -n "${R2_TOUCH_SCOPE:-}" ]]; then
        printf '%s' "${R2_TOUCH_SCOPE}"
        return
    fi

    case "$(uname -s)" in
    Darwin)
        printf 'darwin'
        ;;
    *)
        if [[ -r /proc/sys/kernel/osrelease ]] &&
            grep -qi microsoft /proc/sys/kernel/osrelease; then
            printf 'wsl'
        else
            printf 'linux'
        fi
        ;;
    esac
}

function touch_marker_key() {
    printf '_touch/%s' "$(touch_scope)"
}

function touch_marker_age_seconds() {
    local key="$1"
    local epoch
    local stderr_file
    local stderr_text
    stderr_file="$(mktemp)"

    if ! epoch="$(
        aws s3api head-object \
            --endpoint-url "${AWS_ENDPOINT_URL}" \
            --bucket "${R2_TOUCH_BUCKET}" \
            --key "${key}" \
            --query 'Metadata.unixepoch' \
            --output text 2>"${stderr_file}"
    )"; then
        stderr_text="$(tr '\n' ' ' <"${stderr_file}")"
        rm -f -- "${stderr_file}"
        if [[ "${stderr_text}" != *'404'* && "${stderr_text}" != *'NoSuchKey'* ]]; then
            printf 'Warning: failed to read the touch marker %s: %s\n' \
                "${key}" "${stderr_text}" >&2
        fi
        return 1
    fi
    rm -f -- "${stderr_file}"

    [[ "${epoch}" =~ ^[1-9][0-9]{9}$ ]] || return 1

    printf '%s' "$(($(date +%s) - epoch))"
}

function update_touch_marker() {
    local key="$1"
    local stderr_file
    stderr_file="$(mktemp)"

    for _ in 1 2 3; do
        if aws s3api put-object \
            --endpoint-url "${AWS_ENDPOINT_URL}" \
            --bucket "${R2_TOUCH_BUCKET}" \
            --key "${key}" \
            --metadata "nix-cache-touch=${R2_TOUCH_ID},unixepoch=$(date +%s)" \
            >/dev/null 2>"${stderr_file}"; then
            rm -f -- "${stderr_file}"
            return 0
        fi
        sleep 1
    done

    printf 'put-object %s: %s\n' "${key}" "$(tr '\n' ' ' <"${stderr_file}")" >&2
    rm -f -- "${stderr_file}"
    return 1
}

function touch_cache() (
    set +x

    local marker_key
    local marker_age
    local min_interval=86400
    marker_key="$(touch_marker_key)"

    if marker_age="$(touch_marker_age_seconds "${marker_key}")" &&
        ((marker_age >= 0 && marker_age < min_interval)); then
        printf 'Skipping touch: last refresh was %ss ago (marker %s, interval %ss).\n' \
            "${marker_age}" "${marker_key}" "${min_interval}"
        return 0
    fi

    local errors
    local touchlist
    local narmap
    local missing
    local closure_file=''
    local remove_closure_file='false'
    errors="$(mktemp)"
    touchlist="$(mktemp)"
    narmap="$(mktemp)"
    missing="$(mktemp)"
    export TOUCH_ERRORS="${errors}"
    export TOUCH_LIST="${touchlist}"
    export TOUCH_NAR_MAP="${narmap}"
    export TOUCH_MISSING="${missing}"
    trap 'rm -f -- "${TOUCH_ERRORS}" "${TOUCH_LIST}" "${TOUCH_NAR_MAP}" "${TOUCH_MISSING}"; [[ "${remove_closure_file}" != "true" || -z "${closure_file}" ]] || rm -f -- "${closure_file}"' EXIT

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
            printf "%s\t%s\n" "${url}" "${hash}" >>"${TOUCH_NAR_MAP}"
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

    LC_ALL=C sort -u "${touchlist}" -o "${touchlist}"
    LC_ALL=C sort -u "${narmap}" -o "${narmap}"

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
            stderr_file="$(mktemp)"
            last_error=""

            for attempt in 1 2 3; do
                # R2 MERGE retains source standard and custom metadata.
                if aws s3api copy-object \
                --endpoint-url "${AWS_ENDPOINT_URL}" \
                --bucket "${R2_TOUCH_BUCKET}" \
                --key "${key}" \
                --copy-source "${R2_TOUCH_BUCKET}/${key}" \
                --metadata-directive MERGE \
                --metadata "nix-cache-touch=${R2_TOUCH_ID}" \
                >/dev/null 2>"${stderr_file}"; then
                    refreshed=true
                    break
                fi
                last_error="$(tr "\n" " " <"${stderr_file}")"
                sleep 1
            done

            rm -f -- "${stderr_file}"
            if [[ "${refreshed}" != true ]]; then
                if [[ -n "${last_error}" ]]; then
                    printf "refresh %s: %s\n" "${key}" "${last_error}" >>"${TOUCH_ERRORS}"
                else
                    printf "refresh %s\n" "${key}" >>"${TOUCH_ERRORS}"
                fi
                status=1
            fi
        done
        exit "${status}"
    ' _ || refresh_status=$?

    awk '/NoSuchKey/ { key=$2; sub(/:$/, "", key); if (key ~ /^nar\//) print key }' "${errors}" | LC_ALL=C sort -u >"${missing}" || true
    local missing_count
    missing_count="$(wc -l <"${missing}" | tr -d ' ')"
    local other_failures
    other_failures="$(grep -v "NoSuchKey" "${errors}" | wc -l | tr -d ' ' || true)"
    local repair_status=0
    if ((missing_count > 0)); then
        printf 'Repairing %s stale objects...\n' "${missing_count}"
        export TOUCH_CLOSURE="${closure_file}"
        # shellcheck disable=SC2016
        tr '\n' '\000' <"${missing}" \
            | xargs -0 -n 32 -P 1 bash -c '
        status=0
        for nar_key; do
            parents="$(awk -F "\t" -v nar="${nar_key}" "{ if (\$1 == nar) print \$2 }" "${TOUCH_NAR_MAP}")"
            if [[ -z "${parents}" ]]; then
                printf "repair %s: no parent mapping\n" "${nar_key}" >>"${TOUCH_ERRORS}"
                status=1
                continue
            fi
            store_list="$(mktemp)"
            while IFS= read -r parent_hash; do
                [[ -n "${parent_hash}" ]] || continue
                store_path="$(awk -v h="${parent_hash}" "{ if (index(\$0, \"/\" h \"-\") > 0) { print; exit } }" "${TOUCH_CLOSURE}")"
                if [[ -z "${store_path}" ]]; then
                    printf "repair %s: no store path for parent %s\n" "${nar_key}" "${parent_hash}" >>"${TOUCH_ERRORS}"
                    status=1
                    continue
                fi
                printf "%s\n" "${store_path}" >>"${store_list}"
                rm_ok=false
                rm_err=""
                rm_stderr="$(mktemp)"
                for attempt in 1 2 3; do
                    if aws s3 rm --endpoint-url "${AWS_ENDPOINT_URL}" "s3://${R2_TOUCH_BUCKET}/${parent_hash}.narinfo" >/dev/null 2>"${rm_stderr}"; then
                        rm_ok=true
                        break
                    fi
                    rm_err="$(tr "\n" " " <"${rm_stderr}")"
                    sleep 1
                done
                rm -f -- "${rm_stderr}"
                if [[ "${rm_ok}" == true ]]; then
                    printf "repair %s: removed %s.narinfo\n" "${nar_key}" "${parent_hash}" >>"${TOUCH_ERRORS}"
                else
                    if [[ -n "${rm_err}" ]]; then
                        printf "repair %s: remove %s.narinfo failed: %s\n" "${nar_key}" "${parent_hash}" "${rm_err}" >>"${TOUCH_ERRORS}"
                    else
                        printf "repair %s: remove %s.narinfo failed\n" "${nar_key}" "${parent_hash}" >>"${TOUCH_ERRORS}"
                    fi
                    status=1
                fi
            done <<<"${parents}"
            if [[ ! -s "${store_list}" ]]; then
                printf "repair %s: no store paths to copy\n" "${nar_key}" >>"${TOUCH_ERRORS}"
                rm -f -- "${store_list}"
                status=1
                continue
            fi
            copy_ok=false
            copy_err=""
            verify_err=""
            copy_stderr="$(mktemp)"
            verify_stderr="$(mktemp)"
            retouch_list="$(mktemp)"
            for attempt in 1 2 3; do
                copy_err=""
                verify_err=""
                if nix copy --accept-flake-config --impure --no-update-lock-file --option narinfo-cache-positive-ttl 0 --option narinfo-cache-negative-ttl 0 --to "s3://${R2_TOUCH_BUCKET}?endpoint=${AWS_ENDPOINT_URL}&scheme=https&region=auto" --stdin <"${store_list}" >/dev/null 2>"${copy_stderr}"; then
                    verify_ok=true
                    : >"${retouch_list}"
                    while IFS= read -r parent_hash; do
                        [[ -n "${parent_hash}" ]] || continue
                        if ! aws s3api head-object --endpoint-url "${AWS_ENDPOINT_URL}" --bucket "${R2_TOUCH_BUCKET}" --key "${parent_hash}.narinfo" >/dev/null 2>"${verify_stderr}"; then
                            verify_ok=false
                            verify_err="head-object ${parent_hash}.narinfo: $(tr "\n" " " <"${verify_stderr}")"
                            continue
                        fi
                        narinfo="$(aws s3 cp --endpoint-url "${AWS_ENDPOINT_URL}" "s3://${R2_TOUCH_BUCKET}/${parent_hash}.narinfo" - 2>/dev/null)"
                        url="$(sed -n "s/^URL: //p" <<<"${narinfo}" | head -n 1)"
                        if [[ -z "${url}" ]]; then
                            verify_ok=false
                            verify_err="no URL in ${parent_hash}.narinfo"
                            continue
                        fi
                        if ! aws s3api head-object --endpoint-url "${AWS_ENDPOINT_URL}" --bucket "${R2_TOUCH_BUCKET}" --key "${url}" >/dev/null 2>"${verify_stderr}"; then
                            verify_ok=false
                            verify_err="head-object ${url}: $(tr "\n" " " <"${verify_stderr}")"
                            continue
                        fi
                        printf "%s.narinfo\n" "${parent_hash}" >>"${retouch_list}"
                        printf "%s\n" "${url}" >>"${retouch_list}"
                    done <<<"${parents}"
                    if [[ "${verify_ok}" == true ]]; then
                        copy_ok=true
                        break
                    fi
                else
                    copy_err="$(tr "\n" " " <"${copy_stderr}")"
                fi
                sleep 1
            done
            rm -f -- "${copy_stderr}" "${verify_stderr}"
            if [[ "${copy_ok}" == true ]]; then
                printf "repair %s: copied %s\n" "${nar_key}" "$(tr "\n" " " <"${store_list}")" >>"${TOUCH_ERRORS}"
            else
                if [[ -n "${verify_err}" ]]; then
                    printf "repair %s: verify failed: %s\n" "${nar_key}" "${verify_err}" >>"${TOUCH_ERRORS}"
                elif [[ -n "${copy_err}" ]]; then
                    printf "repair %s: copy failed: %s\n" "${nar_key}" "${copy_err}" >>"${TOUCH_ERRORS}"
                else
                    printf "repair %s: copy failed\n" "${nar_key}" >>"${TOUCH_ERRORS}"
                fi
                rm -f -- "${store_list}" "${retouch_list}"
                status=1
                continue
            fi
            rm -f -- "${store_list}"
            LC_ALL=C sort -u "${retouch_list}" -o "${retouch_list}"
            retouch_ok=true
            while IFS= read -r rkey; do
                [[ -n "${rkey}" ]] || continue
                r_ok=false
                r_err=""
                r_stderr="$(mktemp)"
                for attempt in 1 2 3; do
                    if aws s3api copy-object --endpoint-url "${AWS_ENDPOINT_URL}" --bucket "${R2_TOUCH_BUCKET}" --key "${rkey}" --copy-source "${R2_TOUCH_BUCKET}/${rkey}" --metadata-directive MERGE --metadata "nix-cache-touch=${R2_TOUCH_ID}" >/dev/null 2>"${r_stderr}"; then
                        r_ok=true
                        break
                    fi
                    r_err="$(tr "\n" " " <"${r_stderr}")"
                    sleep 1
                done
                rm -f -- "${r_stderr}"
                if [[ "${r_ok}" == true ]]; then
                    printf "repair %s: retouched %s\n" "${nar_key}" "${rkey}" >>"${TOUCH_ERRORS}"
                else
                    if [[ -n "${r_err}" ]]; then
                        printf "repair %s: retouch %s failed: %s\n" "${nar_key}" "${rkey}" "${r_err}" >>"${TOUCH_ERRORS}"
                    else
                        printf "repair %s: retouch %s failed\n" "${nar_key}" "${rkey}" >>"${TOUCH_ERRORS}"
                    fi
                    retouch_ok=false
                    status=1
                fi
            done <"${retouch_list}"
            rm -f -- "${retouch_list}"
            if [[ "${retouch_ok}" == true ]]; then
                printf "repair %s: ok\n" "${nar_key}" >>"${TOUCH_ERRORS}"
            fi
        done
        exit "${status}"
    ' _ || repair_status=$?
    fi

    if ((refresh_status != 0)); then
        if ((missing_count > 0 && repair_status == 0 && other_failures == 0)); then
            printf 'Repaired %s stale objects.\n' "${missing_count}"
        else
            printf 'Failed to refresh cache objects:\n' >&2
            if [[ -s "${errors}" ]]; then
                cat "${errors}" >&2
            fi
            return 1
        fi
    fi

    if ((total == 0)); then
        printf 'No cache objects were refreshed; not updating the touch marker.\n' >&2
        return 1
    fi

    if ! update_touch_marker "${marker_key}"; then
        printf 'Failed to update the touch marker %s.\n' "${marker_key}" >&2
        return 1
    fi

    printf 'Refreshed %s objects (marker %s updated).\n' "${total}" "${marker_key}"
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
