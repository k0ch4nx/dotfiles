language {
  compatible_with {
    opentofu = "~> 1.13.0"
  }
}

terraform {
  required_providers {
    cloudflare = {
      source  = "registry.terraform.io/cloudflare/cloudflare"
      version = "~> 5.22.0"
    }

    github = {
      source  = "registry.terraform.io/integrations/github"
      version = "~> 6.13.0"
    }
  }
}
