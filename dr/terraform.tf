terraform {
  required_version = "~> 1.14.0"

  cloud {
    organization = "acfaria-hashicorp"

    workspaces {
      name = "tfe-hvd-dr-setup"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}