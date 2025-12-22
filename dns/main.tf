locals {
  lb_dns_name = (
    var.active_region == "dr"
    ? data.terraform_remote_state.dr.outputs.tfe_urls.tfe_lb_dns_name
    : data.terraform_remote_state.primary.outputs.tfe_urls.tfe_lb_dns_name
  )
}

resource "cloudflare_dns_record" "tfe" {
  zone_id = var.cloudflare_zone_id
  name    = "tfe.lab"
  type    = "CNAME"
  content = local.lb_dns_name
  proxied = false
  ttl     = 60
}
