resource "cloudflare_r2_bucket_lifecycle" "nix_cache" {
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.nix_cache.name

  rules = [{
    id      = "expire-after-3d"
    enabled = true

    delete_objects_transition = {
      condition = {
        max_age = 259200
        type    = "Age"
      }
    }
  }]
}
