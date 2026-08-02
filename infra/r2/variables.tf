variable "cloudflare_account_id" {
  type = string

  validation {
    condition     = length(trimspace(var.cloudflare_account_id)) > 0
    error_message = "cloudflare_account_id must not be empty."
  }
}

variable "bucket_name" {
  type    = string
  default = "dotfiles-nix-cache"

  validation {
    condition     = length(trimspace(var.bucket_name)) > 0
    error_message = "bucket_name must not be empty."
  }
}

variable "location" {
  type    = string
  default = "apac"

  validation {
    condition     = contains(["apac", "eeur", "enam", "weur", "wnam", "oc"], var.location)
    error_message = "location must be one of: apac, eeur, enam, weur, wnam, oc."
  }
}

variable "credential_generations" {
  type = set(string)
}
