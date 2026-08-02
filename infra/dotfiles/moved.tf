moved {
  from = cloudflare_r2_bucket.nix_cache
  to   = module.r2.cloudflare_r2_bucket.nix_cache
}

moved {
  from = cloudflare_r2_bucket_lifecycle.nix_cache
  to   = module.r2.cloudflare_r2_bucket_lifecycle.nix_cache
}
