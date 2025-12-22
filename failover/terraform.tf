terraform {
  required_version = "~> 1.14.0"

  cloud {
    organization = "acfaria-hashicorp"

    workspaces {
      name = "tfe-hvd-failover"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.15"
    }
  }
}