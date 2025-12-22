module "vpc" {
  source  = "app.terraform.io/acfaria-hashicorp/vpc/aws"
  version = "1.0.0"

  name = "vpc-demo"
  cidr = "10.11.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.11.1.0/24", "10.11.2.0/24"]
  public_subnets  = ["10.11.11.0/24", "10.11.12.0/24"]

  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "demo"
  }
}

# Create an EC2 Instance Connect Endpoint
# resource "aws_ec2_instance_connect_endpoint" "default" {
#   depends_on = [module.vpc]

#   subnet_id          = module.vpc.private_subnets[0]
#   security_group_ids = [module.vpc.default_security_group_id]
# }

module "tfe" {
  depends_on = [module.vpc]
  source     = "hashicorp/terraform-enterprise-hvd/aws"
  version    = "0.3.0"

  is_secondary_region               = true
  rds_global_cluster_id             = "demo-tfe-rds-global-cluster"
  rds_source_region                 = "us-west-2"                                                                   # primary region
  rds_replication_source_identifier = "arn:aws:rds:us-west-2:008971679752:cluster:demo-tfe-rds-cluster-us-west-2"   # primary region RDS cluster ARN
  rds_kms_key_arn                   = "arn:aws:kms:us-east-2:008971679752:key/mrk-eb58d2059c9b4c55bba0c7047ad93193" # KMS key in DR region replicated from primary

  # --- Common --- #
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- Bootstrap --- #
  tfe_license_secret_arn             = var.tfe_license_secret_arn
  tfe_encryption_password_secret_arn = var.tfe_encryption_password_secret_arn
  tfe_tls_cert_secret_arn            = var.tfe_tls_cert_secret_arn
  tfe_tls_privkey_secret_arn         = var.tfe_tls_privkey_secret_arn
  tfe_tls_ca_bundle_secret_arn       = var.tfe_tls_ca_bundle_secret_arn
  tfe_image_tag                      = var.tfe_image_tag

  # --- TFE configuration settings --- #
  tfe_fqdn               = var.tfe_fqdn
  tfe_operational_mode   = var.tfe_operational_mode
  tfe_metrics_enable     = var.tfe_metrics_enable
  tfe_metrics_http_port  = var.tfe_metrics_http_port
  tfe_metrics_https_port = var.tfe_metrics_https_port

  # --- Networking --- #
  vpc_id                               = var.vpc_id
  lb_is_internal                       = var.lb_is_internal
  lb_subnet_ids                        = var.lb_subnet_ids
  ec2_subnet_ids                       = var.ec2_subnet_ids
  rds_subnet_ids                       = var.rds_subnet_ids
  redis_subnet_ids                     = var.redis_subnet_ids
  cidr_allow_ingress_tfe_443           = var.cidr_allow_ingress_tfe_443
  cidr_allow_ingress_ec2_ssh           = var.cidr_allow_ingress_ec2_ssh
  cidr_allow_ingress_tfe_metrics_http  = var.cidr_allow_ingress_tfe_metrics_http
  cidr_allow_ingress_tfe_metrics_https = var.cidr_allow_ingress_tfe_metrics_https

  # --- DNS (optional) --- #
  create_route53_tfe_dns_record      = var.create_route53_tfe_dns_record
  route53_tfe_hosted_zone_name       = var.route53_tfe_hosted_zone_name
  route53_tfe_hosted_zone_is_private = var.route53_tfe_hosted_zone_is_private

  # --- Compute --- #
  container_runtime  = var.container_runtime
  ec2_os_distro      = var.ec2_os_distro
  ec2_ssh_key_pair   = var.ec2_ssh_key_pair
  ec2_allow_ssm      = var.ec2_allow_ssm
  ec2_instance_size  = var.ec2_instance_size
  asg_instance_count = var.asg_instance_count

  # --- Database --- #
  tfe_database_password_secret_arn = var.tfe_database_password_secret_arn
  tfe_database_name                = var.tfe_database_name
  tfe_database_user                = var.tfe_database_user
  tfe_database_parameters          = var.tfe_database_parameters
  rds_aurora_engine_version        = var.rds_aurora_engine_version
  rds_parameter_group_family       = var.rds_parameter_group_family
  rds_aurora_instance_class        = var.rds_aurora_instance_class
  rds_aurora_replica_count         = var.rds_aurora_replica_count
  rds_skip_final_snapshot          = var.rds_skip_final_snapshot

  # --- Redis --- #
  tfe_redis_password_secret_arn    = var.tfe_redis_password_secret_arn
  redis_engine_version             = var.redis_engine_version
  redis_parameter_group_name       = var.redis_parameter_group_name
  redis_node_type                  = var.redis_node_type
  redis_multi_az_enabled           = var.redis_multi_az_enabled
  redis_automatic_failover_enabled = var.redis_automatic_failover_enabled

  # --- Log forwarding (optional) --- #
  tfe_log_forwarding_enabled = var.tfe_log_forwarding_enabled
  log_fwd_destination_type   = var.log_fwd_destination_type
  s3_log_fwd_bucket_name     = var.s3_log_fwd_bucket_name
  #cloudwatch_log_group_name = var.cloudwatch_log_group_name
}