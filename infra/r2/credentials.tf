data "cloudflare_account_api_token_permission_groups_list" "r2_read" {
  account_id = var.cloudflare_account_id
  name       = "Workers R2 Storage Bucket Item Read"
}

data "cloudflare_account_api_token_permission_groups_list" "r2_write" {
  account_id = var.cloudflare_account_id
  name       = "Workers R2 Storage Bucket Item Write"
}

locals {
  credentials = {
    for pair in setproduct(var.credential_generations, ["read", "write"]) :
    "${pair[0]}:${pair[1]}" => {
      generation = pair[0]
      mode       = pair[1]
    }
  }

  permission_group_ids = {
    read = [
      one(data.cloudflare_account_api_token_permission_groups_list.r2_read.result).id,
    ]
    write = [
      one(data.cloudflare_account_api_token_permission_groups_list.r2_read.result).id,
      one(data.cloudflare_account_api_token_permission_groups_list.r2_write.result).id,
    ]
  }

  r2_bucket_resource = "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${var.bucket_name}"
}

resource "cloudflare_account_token" "r2" {
  for_each = local.credentials

  account_id = var.cloudflare_account_id
  name       = "tf-${var.bucket_name}-${each.value.mode}-${each.value.generation}"
  policies = [{
    effect = "allow"
    permission_groups = [
      for permission_group_id in local.permission_group_ids[each.value.mode] : {
        id = permission_group_id
      }
    ]
    resources = jsonencode({
      (local.r2_bucket_resource) = "*"
    })
  }]

  depends_on = [cloudflare_r2_bucket.nix_cache]
}
