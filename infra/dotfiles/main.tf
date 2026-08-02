module "r2" {
  source = "../r2"

  bucket_name            = var.bucket_name
  cloudflare_account_id  = var.cloudflare_account_id
  credential_generations = var.r2_credential_generations
  location               = var.location
}

locals {
  active_r2_credentials = module.r2.credentials[var.active_r2_credential_generation]
}

module "github" {
  source = "../github"

  actions_secrets = {
    R2_RO_ACCESS_KEY_ID     = local.active_r2_credentials.ro_access_key_id
    R2_RO_SECRET_ACCESS_KEY = local.active_r2_credentials.ro_secret_access_key
    R2_RW_ACCESS_KEY_ID     = local.active_r2_credentials.rw_access_key_id
    R2_RW_SECRET_ACCESS_KEY = local.active_r2_credentials.rw_secret_access_key
  }
  owner      = var.github_owner
  repository = var.github_repository
}

check "active_r2_credential_generation" {
  assert {
    condition     = contains(var.r2_credential_generations, var.active_r2_credential_generation)
    error_message = "active_r2_credential_generation must be included in r2_credential_generations."
  }
}
