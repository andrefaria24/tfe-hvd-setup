data "terraform_remote_state" "primary" {
  backend = "remote"
  config = {
    organization = "acfaria-hashicorp"
    workspaces   = { name = "tfe-hvd-setup" }
  }
}

data "terraform_remote_state" "dr" {
  backend = "remote"
  config = {
    organization = "acfaria-hashicorp"
    workspaces   = { name = "tfe-hvd-dr-setup" }
  }
}