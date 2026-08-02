output "bucket_name" {
  value = module.r2.bucket_name
}

output "s3_endpoint" {
  value = module.r2.s3_endpoint
}

output "r2_ro_access_key_id" {
  value     = local.active_r2_credentials.ro_access_key_id
  sensitive = true
}

output "r2_ro_secret_access_key" {
  value     = local.active_r2_credentials.ro_secret_access_key
  sensitive = true
}

output "r2_rw_access_key_id" {
  value     = local.active_r2_credentials.rw_access_key_id
  sensitive = true
}

output "r2_rw_secret_access_key" {
  value     = local.active_r2_credentials.rw_secret_access_key
  sensitive = true
}
