output "bucket_name" {
  value = cloudflare_r2_bucket.nix_cache.name
}

output "s3_endpoint" {
  value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}
