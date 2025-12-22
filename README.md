# Terraform Enterprise HVD Setup

This repository provides Terraform configurations to deploy Terraform Enterprise (TFE) using the HashiCorp Validated Design (HVD) module. It supports single-region (primary only) and multi-region (primary + DR) deployments, with a documented DR failover procedure.

![TFE multi-region architecture](tfe-multiregion.png)

## Repo layout

- `primary/` - Primary region TFE deployment using the HVD module.
- `dr/` - DR region TFE deployment configured as the Aurora Global Database replica. Includes optional VPC creation for demo purposes.
- `README.md` - This guide.

## Configure TFE for single-region

Use the `primary/` directory only.

1) Copy and edit the variables file:

```powershell
Copy-Item primary/terraform.tfvars.example primary/terraform.tfvars
```

2) Update `primary/terraform.tfvars` with your values:
- `region`
- `vpc_id`, `lb_subnet_ids`, `ec2_subnet_ids`, `rds_subnet_ids`, `redis_subnet_ids`
- `tfe_fqdn`, secrets ARNs, and sizing settings
- `create_route53_tfe_dns_record` (set `false` if using Cloudflare)

3) Apply:

```powershell
cd primary
terraform init
terraform apply
```

The primary outputs include `tfe_urls.tfe_lb_dns_name`, which you can use for DNS in Cloudflare.

## Configure TFE for multi-region (primary + DR)

Deploy primary first, then DR.

### Primary

Follow the single-region steps above and apply in `primary/`.

### DR

1) Copy and edit the variables file:

```powershell
Copy-Item dr/terraform.tfvars.example dr/terraform.tfvars
```

2) Update `dr/terraform.tfvars` with your DR region values. In `dr/main.tf`, set the Aurora Global Database replication inputs (these are required for the secondary region):
- `rds_global_cluster_id` (from primary output)
- `rds_source_region` (primary region)
- `rds_replication_source_identifier` (primary RDS cluster ARN)
- `rds_kms_key_arn` (KMS key in DR region replicated from primary)

3) Apply in `dr/`:

```powershell
cd dr
terraform init
terraform apply
```

The DR outputs include `tfe_urls.tfe_lb_dns_name` for DNS failover.

## DNS module (Cloudflare)

Use the `dns/` directory to manage the Cloudflare DNS alias that points to the active region's NLB.

1) Copy and edit the variables file:

```powershell
Copy-Item dns/terraform.tfvars.example dns/terraform.tfvars
```

2) Update `dns/terraform.tfvars`:
- `cloudflare_api_token`
- `cloudflare_zone_id`
- `active_region` (`primary` or `dr`)

3) If you need a different DNS name, update `name` in `dns/main.tf`.

4) Apply:

```powershell
cd dns
terraform init
terraform apply
```

Switching DNS during failover/failback is done by changing `active_region` and re-applying.

Example to fail over DNS to DR:

```powershell
cd dns
terraform apply -var "active_region=dr"
```

## DR failover: primary to DR

Follow the sequence below during a regional failover.

1) Bring the DR ASG to 1:

```powershell
cd dr
terraform apply -var "asg_instance_count=1"
```

2) Fail over Aurora Global Database to DR (AWS CLI example):

```bash
aws rds failover-global-cluster \
  --global-cluster-identifier <rds_global_cluster_id> \
  --target-db-cluster-identifier <dr_rds_cluster_arn>
```

You can get the identifiers from `primary/outputs.tf` and `dr/outputs.tf` via `terraform output -json`.

3) Update Cloudflare DNS to point to the DR NLB:

- Use the DR output `tfe_urls.tfe_lb_dns_name` as the new record target.
- Update your Cloudflare record (CNAME or flattened CNAME at apex) to the DR NLB DNS name.

Optionally, scale down the primary ASG after failover:

```powershell
cd primary
terraform apply -var "asg_instance_count=0"
```

## DR failback: DR to primary

Use this sequence once the primary region is healthy again.

1) Bring the primary ASG back to 1:

```powershell
cd primary
terraform apply -var "asg_instance_count=1"
```

2) Switch the Aurora Global Database back to primary (AWS CLI example):

```bash
aws rds switchover-global-cluster \
  --global-cluster-identifier <rds_global_cluster_id> \
  --target-db-cluster-identifier <primary_rds_cluster_arn>
```

3) Update Cloudflare DNS to point back to the primary NLB:

- Use the primary output `tfe_urls.tfe_lb_dns_name` as the record target.
- Update your Cloudflare record (CNAME or flattened CNAME at apex) to the primary NLB DNS name.

Optionally, scale down the DR ASG after failback:

```powershell
cd dr
terraform apply -var "asg_instance_count=0"
```
