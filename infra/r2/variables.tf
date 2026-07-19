variable "cloudflare_account_id" {
  description = "Cloudflare account ID that owns the R2 bucket."
  type        = string

  validation {
    condition     = length(trimspace(var.cloudflare_account_id)) > 0
    error_message = "cloudflare_account_id must not be empty."
  }
}

variable "bucket_name" {
  description = "Name of the private R2 bucket used as the Nix binary cache."
  type        = string
  default     = "dotfiles-nix-cache"

  validation {
    condition     = length(trimspace(var.bucket_name)) > 0
    error_message = "bucket_name must not be empty."
  }
}

variable "location" {
  description = "R2 location hint used when the bucket is first created."
  type        = string
  default     = "apac"

  validation {
    condition     = contains(["apac", "eeur", "enam", "weur", "wnam", "oc"], var.location)
    error_message = "location must be one of: apac, eeur, enam, weur, wnam, oc."
  }
}
