#!/usr/bin/env bash

set -euo pipefail

function read_r2_terraform_outputs() (
    set +x

    [[ -n "${DOTFILES_DIR:-}" ]]

    local mode="${1:-}"
    case "${mode}" in
    ro | rw) ;;
    *)
        printf 'R2 credential mode must be ro or rw.\n' >&2
        return 1
        ;;
    esac

    if ! declare -F read_scalr_token >/dev/null; then
        DOTFILES_AUTH_SKIP_MAIN='1'
        export DOTFILES_AUTH_SKIP_MAIN
        # shellcheck disable=SC1091
        source "${DOTFILES_DIR}/scripts/steps/020-prepare-terraform-auth.sh"
        unset DOTFILES_AUTH_SKIP_MAIN
    fi

    umask 077

    local temporary_directory
    if ! temporary_directory="$(mktemp -d)"; then
        printf 'Failed to create a private temporary directory for Scalr requests.\n' >&2
        return 1
    fi
    # shellcheck disable=SC2064
    trap "rm -rf -- $(printf '%q' "${temporary_directory}")" EXIT

    local scalr_host='k0ch4nx.scalr.io'
    local environment_id='env-v0pgfafrhal0sb1mm'
    local workspace_name='nix-cache'
    local expected_s3_endpoint='https://6118f982b348f7b37129655ee4160301.r2.cloudflarestorage.com'

    local token
    if ! token="$(read_scalr_token)"; then
        printf 'Failed to read the Scalr token.\n' >&2
        return 1
    fi

    if [[ -z "${token}" || "${token}" == *[[:space:]]* ]]; then
        printf 'The Scalr token has an invalid value.\n' >&2
        return 1
    fi

    local header_file="${temporary_directory}/request.headers"
    if ! {
        printf 'Authorization: Bearer %s\n' "${token}"
        printf 'Accept: application/vnd.api+json\n'
        printf 'Content-Type: application/vnd.api+json\n'
    } >"${header_file}"; then
        printf 'Failed to prepare the Scalr request headers.\n' >&2
        return 1
    fi
    unset token

    function scalr_get_json() {
        local url="$1"
        local output_file="$2"
        local http_status

        if ! http_status="$(
            curl \
                -q \
                --fail \
                --silent \
                --show-error \
                --proto '=https' \
                --max-redirs 0 \
                --connect-timeout 10 \
                --max-time 60 \
                --header @"${header_file}" \
                --output "${output_file}" \
                --write-out '%{http_code}' \
                "${url}"
        )"; then
            printf 'Scalr API request failed: %s\n' "${url}" >&2
            return 1
        fi

        if [[ "${http_status}" != '200' ]]; then
            printf 'Scalr API returned HTTP %s: %s\n' "${http_status}" "${url}" >&2
            return 1
        fi
    }

    local workspace_response="${temporary_directory}/workspace.json"
    local outputs_response="${temporary_directory}/outputs.json"

    if ! scalr_get_json \
        "https://${scalr_host}/api/iacp/v3/workspaces?filter%5Benvironment%5D=${environment_id}&filter%5Bname%5D=${workspace_name}&page%5Bsize%5D=100" \
        "${workspace_response}"; then
        return 1
    fi

    local workspace_id
    if ! workspace_id="$(
        SCALR_RESPONSE_FILE="${workspace_response}" \
            SCALR_ENVIRONMENT_ID="${environment_id}" \
            SCALR_WORKSPACE_NAME="${workspace_name}" \
            nix eval \
            --impure \
            --raw \
            --expr '
                let
                  response = builtins.fromJSON (
                    builtins.readFile (builtins.getEnv "SCALR_RESPONSE_FILE")
                  );
                  environmentId = builtins.getEnv "SCALR_ENVIRONMENT_ID";
                  workspaceName = builtins.getEnv "SCALR_WORKSPACE_NAME";
                  data = response.data;
                  links = if response ? links then response.links else null;
                  hasNext = builtins.isAttrs links && (links ? next) && links.next != null;
                  isMatch = workspace:
                    builtins.isAttrs workspace
                    && (workspace ? type) && workspace.type == "workspaces"
                    && (workspace ? attributes) && builtins.isAttrs workspace.attributes
                    && (workspace.attributes ? name) && workspace.attributes.name == workspaceName
                    && (workspace ? relationships) && builtins.isAttrs workspace.relationships
                    && (workspace.relationships ? environment) && builtins.isAttrs workspace.relationships.environment
                    && (workspace.relationships.environment ? data) && builtins.isAttrs workspace.relationships.environment.data
                    && (workspace.relationships.environment.data ? id)
                    && workspace.relationships.environment.data.id == environmentId;
                  matches = if builtins.isList data then builtins.filter isMatch data else [];
                in
                if hasNext then
                  throw "Expected a single page of Scalr workspaces"
                else if !builtins.isList data then
                  throw "Expected a Scalr workspace list"
                else if builtins.length matches != 1 then
                  throw "Expected exactly one matching Scalr workspace"
                else
                  (builtins.head matches).id
            ' 2>/dev/null
    )"; then
        printf 'Scalr workspace lookup failed for environment %s.\n' "${environment_id}" >&2
        return 1
    fi

    if [[ ! "${workspace_id}" =~ ^ws-[a-z0-9]+$ ]]; then
        printf 'Scalr returned an invalid workspace ID.\n' >&2
        return 1
    fi

    if ! scalr_get_json \
        "https://${scalr_host}/api/iacp/v3/workspaces/${workspace_id}/outputs?sensitive=true" \
        "${outputs_response}"; then
        return 1
    fi

    rm -f -- "${header_file}"

    function read_output() {
        local output_name="$1"
        local value

        if ! value="$(
            SCALR_RESPONSE_FILE="${outputs_response}" \
                SCALR_OUTPUT_NAME="${output_name}" \
                nix eval \
                --impure \
                --raw \
                --expr '
                    let
                      response = builtins.fromJSON (
                        builtins.readFile (builtins.getEnv "SCALR_RESPONSE_FILE")
                      );
                      outputName = builtins.getEnv "SCALR_OUTPUT_NAME";
                      data = response.data;
                      links = if response ? links then response.links else null;
                      hasNext = builtins.isAttrs links && (links ? next) && links.next != null;
                      isMatch = output:
                        builtins.isAttrs output
                        && (output ? name)
                        && output.name == outputName;
                      matches = if builtins.isList data then builtins.filter isMatch data else [];
                      matched = if builtins.length matches == 1 then builtins.head matches else null;
                      value =
                        if builtins.isAttrs matched && (matched ? value) then matched.value else null;
                    in
                    if hasNext then
                      throw "Expected a single page of Scalr workspace outputs"
                    else if !builtins.isList data then
                      throw "Expected a Scalr workspace output list"
                    else if builtins.length matches != 1 then
                      throw "Expected exactly one matching Scalr workspace output"
                    else if !builtins.isString value then
                      throw "Expected the Scalr workspace output to be a non-null string"
                    else if value == "" then
                      throw "Expected the Scalr workspace output to be non-empty"
                    else if value != builtins.replaceStrings [ "\n" "\r" "\t" ] [ "" "" "" ] value then
                      throw "Expected the Scalr workspace output to contain no control characters"
                    else
                      value
                ' 2>/dev/null
        )"; then
            printf 'Scalr workspace output %s is unavailable or invalid.\n' "${output_name}" >&2
            return 1
        fi

        printf '%s' "${value}"
    }

    local bucket_name
    local s3_endpoint
    local access_key_id
    local secret_access_key

    if ! bucket_name="$(read_output 'bucket_name')"; then
        return 1
    fi
    if ! s3_endpoint="$(read_output 's3_endpoint')"; then
        return 1
    fi
    if ! access_key_id="$(read_output "r2_${mode}_access_key_id")"; then
        return 1
    fi
    if ! secret_access_key="$(read_output "r2_${mode}_secret_access_key")"; then
        return 1
    fi

    if [[ ! "${bucket_name}" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]]; then
        printf 'Scalr output bucket_name is not a valid R2 bucket name.\n' >&2
        return 1
    fi

    if [[ "${s3_endpoint}" != "${expected_s3_endpoint}" ]]; then
        printf 'Scalr output s3_endpoint is not the expected Cloudflare R2 endpoint.\n' >&2
        return 1
    fi

    if [[ ! "${access_key_id}" =~ ^[0-9a-fA-F]{32}$ ]]; then
        printf 'Scalr returned an invalid R2 %s access key ID.\n' "${mode}" >&2
        return 1
    fi

    if [[ ! "${secret_access_key}" =~ ^[0-9a-fA-F]{64}$ ]]; then
        printf 'Scalr returned an invalid R2 %s secret access key.\n' "${mode}" >&2
        return 1
    fi

    printf '%s\t%s\t%s\t%s\n' \
        "${bucket_name}" \
        "${s3_endpoint}" \
        "${access_key_id}" \
        "${secret_access_key}"
)
