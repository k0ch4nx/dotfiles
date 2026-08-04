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

variable "github_owner" {
  type    = string
  default = "k0ch4nx"
}

variable "github_repository" {
  type    = string
  default = "dotfiles"
}

# Keep the previous generation during rotation so consumers can transition after apply.
variable "r2_credential_generations" {
  type    = set(string)
  default = ["v1", "v2"]

  validation {
    condition = alltrue([
      for generation in var.r2_credential_generations : length(trimspace(generation)) > 0
    ])
    error_message = "r2_credential_generations must not contain empty values."
  }
}

variable "active_r2_credential_generation" {
  type    = string
  default = "v2"

  validation {
    condition     = length(trimspace(var.active_r2_credential_generation)) > 0
    error_message = "active_r2_credential_generation must not be empty."
  }
}
