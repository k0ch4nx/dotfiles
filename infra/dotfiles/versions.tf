terraform {
  required_version = "~> 1.15.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.22.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 6.13.0"
    }
  }
}
