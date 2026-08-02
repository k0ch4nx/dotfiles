terraform {
  cloud {
    organization = "k0ch4nx"

    workspaces {
      name = "nix-cache"
    }
  }
}
