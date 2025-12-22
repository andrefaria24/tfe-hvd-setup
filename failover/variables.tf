variable "active_region" {
  type    = string
  default = "primary"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type      = string
  sensitive = true
}

variable "global_cluster_identifier" {
  type        = string
  description = "ID of the Aurora Global Database cluster. Leave null to use remote state from the primary workspace."
  default     = null
}

variable "target_db_cluster_identifier" {
  type        = string
  description = "ARN of the target DB cluster to promote. Leave null to derive from active_region and remote state."
  default     = null
}

variable "action" {
  type        = string
  description = "AWS RDS action to run. Valid values are failover-global-cluster or switchover-global-cluster."
  default     = "failover-global-cluster"

  validation {
    condition     = contains(["failover-global-cluster", "switchover-global-cluster"], var.action)
    error_message = "action must be failover-global-cluster or switchover-global-cluster."
  }
}

variable "region" {
  type        = string
  description = "AWS region for the API call. Leave null to use the AWS CLI default."
  default     = null
}

variable "run_id" {
  type        = string
  description = "Change this value to force a re-run with the same inputs (for example, a timestamp)."
  default     = ""
}

variable "enabled" {
  type        = bool
  description = "Set to false to disable the action without removing the module."
  default     = true
}
