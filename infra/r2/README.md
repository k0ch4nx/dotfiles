# Cloudflare R2 Terraform

This directory manages only the private Cloudflare R2 bucket used by the Nix binary cache.
Terraform state is stored in HCP Terraform, while all Terraform commands that can change infrastructure run on GitHub-hosted runners.

## Managed resource

- R2 bucket: `dotfiles-nix-cache` by default
- Location hint: `apac`
- Storage class: `Standard`
- Destruction protection: `prevent_destroy = true`

Public Development URLs, custom domains, CORS rules, lifecycle rules, R2 access keys, and Nix signing keys are intentionally not managed here.

## HCP Terraform

Create the workspace before running the workflow.

- Workspace: `dotfiles-r2`
- Execution mode: `Local`

The empty `cloud {}` block is configured by these GitHub repository variables:

- `TF_CLOUD_ORGANIZATION`
- `TF_WORKSPACE` (`dotfiles-r2`)

The HCP Terraform token is stored as the repository secret `TF_API_TOKEN`.

## Cloudflare authentication

Store the Cloudflare account ID as the repository variable `CLOUDFLARE_ACCOUNT_ID` and the API token as the repository secret `CLOUDFLARE_API_TOKEN`.
The token must be scoped to the target account and have only `Workers R2 Storage Write` permission.

The bucket name is supplied by the repository variable `R2_CACHE_BUCKET` and should be set to `dotfiles-nix-cache`.

## GitHub Environment

Create a GitHub Environment named `terraform-r2` with:

- Deployment branches restricted to `main`
- Required reviewers enabled
- Prevent self-review disabled

Only the `apply` job uses this Environment.

## Workflow behavior

`.github/workflows/terraform-r2.yml` performs:

- Pull requests: `fmt`, backend-free `init`, and `validate` without secrets
- Pushes to `main` and manual runs from `main`: authenticated `plan`
- After Environment approval: application of the exact saved plan artifact from the same workflow run

The plan artifact is retained for seven days. If approval occurs after expiration, rerun the workflow to create a new plan.

Do not use local `terraform apply` for normal operation. Local formatting and validation are acceptable, but infrastructure changes must go through GitHub Actions.

## Initial setup checklist

1. Create the HCP Terraform organization and `dotfiles-r2` workspace.
2. Set the workspace execution mode to `Local`.
3. Add all repository variables and secrets listed above.
4. Create and protect the `terraform-r2` GitHub Environment.
5. Merge the Terraform change into `main`.
6. Review the plan in the workflow summary and approve the `apply` job.

If a bucket with the final name already exists, do not apply until it has either been removed or imported into the HCP Terraform state.
