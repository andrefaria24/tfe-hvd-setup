locals {
  lb_dns_name = (
    var.active_region == "dr"
    ? data.terraform_remote_state.dr.outputs.tfe_urls.tfe_lb_dns_name
    : data.terraform_remote_state.primary.outputs.tfe_urls.tfe_lb_dns_name
  )
}

locals {
  global_cluster_identifier = (
    var.global_cluster_identifier != null && var.global_cluster_identifier != ""
    ? var.global_cluster_identifier
    : data.terraform_remote_state.primary.outputs.database.rds_global_cluster_id
  )
  target_db_cluster_identifier = (
    var.target_db_cluster_identifier != null && var.target_db_cluster_identifier != ""
    ? var.target_db_cluster_identifier
    : (
      var.active_region == "dr"
      ? data.terraform_remote_state.dr.outputs.database.rds_cluster_arn
      : data.terraform_remote_state.primary.outputs.database.rds_cluster_arn
    )
  )
  effective_region = (
    var.region != null && var.region != ""
    ? var.region
    : (
      var.active_region == "dr"
      ? data.terraform_remote_state.dr.outputs.region
      : data.terraform_remote_state.primary.outputs.region
    )
  )
  region_arg = local.effective_region == null || local.effective_region == "" ? "" : " --region ${local.effective_region}"
  command    = "aws rds ${var.action} --global-cluster-identifier ${local.global_cluster_identifier} --target-db-cluster-identifier ${local.target_db_cluster_identifier}${local.region_arg}"
}

resource "cloudflare_dns_record" "tfe" {
  zone_id = var.cloudflare_zone_id
  name    = "tfe.lab"
  type    = "CNAME"
  content = local.lb_dns_name
  proxied = false
  ttl     = 60
}

resource "null_resource" "db_failover" {
  count = var.enabled ? 1 : 0

  triggers = {
    action                       = var.action
    global_cluster_identifier    = local.global_cluster_identifier
    target_db_cluster_identifier = local.target_db_cluster_identifier
    region                       = local.effective_region == null ? "" : local.effective_region
    run_id                       = var.run_id
  }

  provisioner "local-exec" {
    command = local.command
  }
}
