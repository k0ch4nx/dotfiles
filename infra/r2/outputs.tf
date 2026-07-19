output "bucket_name" {
  description = "Name of the R2 bucket used as the Nix binary cache."
  value       = cloudflare_r2_bucket.nix_cache.name
}

output "s3_endpoint" {
  description = "S3-compatible endpoint for the Cloudflare account."
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}
