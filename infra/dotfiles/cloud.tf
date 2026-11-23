terraform {
  backend "remote" {
    hostname     = "k0ch4nx.scalr.io"
    organization = "env-v0pgfafrhal0sb1mm"

    workspaces {
      name = "nix-cache"
    }
  }
}
