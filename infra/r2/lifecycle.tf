resource "cloudflare_r2_bucket_lifecycle" "nix_cache" {
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.nix_cache.name

  rules = [{
    id      = "delete-after-seven-days"
    enabled = true

    conditions = {
      prefix = ""
    }

    delete_objects_transition = {
      condition = {
        max_age = 604800
        type    = "Age"
      }
    }
  }]
}
