data "terraform_remote_state" "primary" {
  backend = "remote"
  config = {
    organization = "acfaria-hashicorp"
    workspaces   = { name = "tfe-hvd-setup" }
  }
}

data "aws_kms_alias" "rds" {
  name = "alias/tfe-rds" # Use your alias for the replicated CMK in the DR region
}