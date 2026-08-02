output "bucket_name" {
  value = cloudflare_r2_bucket.nix_cache.name
}

output "s3_endpoint" {
  value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}

output "credentials" {
  value = {
    for generation in var.credential_generations : generation => {
      ro_access_key_id     = cloudflare_account_token.r2["${generation}:read"].id
      ro_secret_access_key = sha256(cloudflare_account_token.r2["${generation}:read"].value)
      rw_access_key_id     = cloudflare_account_token.r2["${generation}:write"].id
      rw_secret_access_key = sha256(cloudflare_account_token.r2["${generation}:write"].value)
    }
  }
  sensitive = true
}
