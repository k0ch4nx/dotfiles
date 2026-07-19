resource "cloudflare_r2_bucket" "nix_cache" {
  account_id    = var.cloudflare_account_id
  name          = var.bucket_name
  location      = var.location
  storage_class = "Standard"

  lifecycle {
    prevent_destroy = true
  }
}
