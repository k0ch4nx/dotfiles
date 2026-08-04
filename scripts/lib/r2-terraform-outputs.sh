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

    if ! declare -F read_hcp_terraform_token >/dev/null; then
        # shellcheck disable=SC1091
        source "${DOTFILES_DIR}/scripts/steps/030-prepare-terraform-auth.sh"
    fi

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "${temporary_directory}"' EXIT
    umask 077

    local hcp_token
    hcp_token="$(read_hcp_terraform_token)"

    if [[ -z "${hcp_token}" || "${hcp_token}" == *$'\n'* || "${hcp_token}" == *$'\r'* ]]; then
        printf 'The HCP Terraform token has an invalid value.\n' >&2
        return 1
    fi

    local workspace_response="${temporary_directory}/workspace.json"
    local outputs_response="${temporary_directory}/outputs.json"

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --header "Authorization: Bearer ${hcp_token}" \
        --header 'Content-Type: application/vnd.api+json' \
        --output "${workspace_response}" \
        'https://app.terraform.io/api/v2/organizations/k0ch4nx/workspaces/nix-cache'

    local workspace_id
    workspace_id="$(
        HCP_RESPONSE_FILE="${workspace_response}" \
            nix eval \
            --impure \
            --raw \
            --expr '
                let
                  response = builtins.fromJSON (
                    builtins.readFile (builtins.getEnv "HCP_RESPONSE_FILE")
                  );
                in
                response.data.id
            '
    )"

    if [[ "${workspace_id}" != ws-* ]]; then
        printf 'HCP Terraform returned an invalid workspace ID.\n' >&2
        return 1
    fi

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --header "Authorization: Bearer ${hcp_token}" \
        --header 'Content-Type: application/vnd.api+json' \
        --output "${outputs_response}" \
        "https://app.terraform.io/api/v2/workspaces/${workspace_id}/current-state-version-outputs?page%5Bsize%5D=100"

    function read_output() {
        local output_name="$1"
        local output_id

        output_id="$(
            HCP_RESPONSE_FILE="${outputs_response}" \
                HCP_OUTPUT_NAME="${output_name}" \
                nix eval \
                --impure \
                --raw \
                --expr '
                    let
                      response = builtins.fromJSON (
                        builtins.readFile (builtins.getEnv "HCP_RESPONSE_FILE")
                      );
                      outputName = builtins.getEnv "HCP_OUTPUT_NAME";
                      matches = builtins.filter (
                        output: output.attributes.name == outputName
                      ) response.data;
                    in
                    if builtins.length matches != 1 then
                      throw "Expected exactly one matching Terraform output"
                    else
                      (builtins.head matches).id
                '
        )"

        if [[ "${output_id}" != wsout-* ]]; then
            printf 'Terraform output %s has an invalid ID.\n' "${output_name}" >&2
            return 1
        fi

        local output_response="${temporary_directory}/${output_name}.json"

        curl \
            --fail \
            --silent \
            --show-error \
            --location \
            --header "Authorization: Bearer ${hcp_token}" \
            --header 'Content-Type: application/vnd.api+json' \
            --output "${output_response}" \
            "https://app.terraform.io/api/v2/state-version-outputs/${output_id}"

        local value
        value="$(
            HCP_RESPONSE_FILE="${output_response}" \
                nix eval \
                --impure \
                --raw \
                --expr '
                    let
                      response = builtins.fromJSON (
                        builtins.readFile (builtins.getEnv "HCP_RESPONSE_FILE")
                      );
                      value = response.data.attributes.value;
                    in
                    if !builtins.isString value then
                      throw "Expected the Terraform output to be a string"
                    else
                      value
                '
        )"

        if [[ -z "${value}" || "${value}" == *$'\n'* || "${value}" == *$'\r'* ]]; then
            printf 'Terraform output %s has an invalid value.\n' "${output_name}" >&2
            return 1
        fi

        printf '%s' "${value}"
    }

    local bucket_name
    local s3_endpoint
    local access_key_id
    local secret_access_key

    bucket_name="$(read_output 'bucket_name')"
    s3_endpoint="$(read_output 's3_endpoint')"
    access_key_id="$(read_output "r2_${mode}_access_key_id")"
    secret_access_key="$(read_output "r2_${mode}_secret_access_key")"

    if [[ "${bucket_name}" == *['/?&#']* ]]; then
        printf 'Terraform output bucket_name is not a valid S3 bucket name.\n' >&2
        return 1
    fi

    if [[ "${s3_endpoint}" != https://* || "${s3_endpoint#https://}" == */* ]]; then
        printf 'Terraform output s3_endpoint is not a valid HTTPS endpoint.\n' >&2
        return 1
    fi

    if [[ "${#access_key_id}" -ne 32 || "${#secret_access_key}" -ne 64 ]]; then
        printf 'Terraform returned invalid R2 %s credentials.\n' "${mode}" >&2
        return 1
    fi

    printf '%s\t%s\t%s\t%s\n' \
        "${bucket_name}" \
        "${s3_endpoint}" \
        "${access_key_id}" \
        "${secret_access_key}"
)
