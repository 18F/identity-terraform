# Locals

locals {
  db_subnets = var.db_subnet_ids == [] ? {} : var.az_cidr_map
  subnet_group = var.db_subnet_group == "" ? join("-", [
  var.name_prefix, var.env_name, "db"]) : var.db_subnet_group
}

variable "db_engine" {
  type        = string
  description = "AuroraDB engine name (aurora, aurora-mysql or aurora-postgresql)"
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  type        = string
  description = "Version number (e.g. ##.#) of db_engine to use"
  default     = "13.5"
}

variable "db_port" {
  type        = number
  description = "Database port number"
  default     = 5432
}

variable "region" {
  type        = string
  description = "Primary AWS Region"
  default     = "us-west-2"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "login"
}

variable "env_name" {
  type        = string
  description = "Environment name"
}

# RDS information

variable "db_id" {
  type        = string
  description = "Unique identifier for the AuroraDB cluster, e.g. default, master"
}

variable "rds_db_arn" {
  type        = string
  description = <<EOM
(OPTIONAL) ARN of RDS DB used as replication source for AuroraDB cluster. Leave blank
if not using an RDS DB as a replication source / creating a standalone cluster. 
EOM
}

variable "primary_cluster_instances" {
  description = <<EOM
Number of instances to create for the primary AuroraDB cluster. MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
  type        = number
  default     = 2
}

variable "db_instance_class" {
  type        = string
  description = "Instance class to use in AuroraDB cluster"
  default     = "db.r5.large"
}

variable "cw_logs_exports" {
  type        = list(string)
  description = <<EOM
(REQUIRED) List of log types to export to CloudWatch. Will use 'general'
if not specified, or 'postgresql' if var.db_engine is 'aurora-postgresql'.
EOM
  default     = []
}

variable "retention_period" {
  type        = number
  description = "Number of days to retain backups for"
  default     = 34
}

variable "backup_window" {
  type        = string
  description = "Daily time range (in UTC) for automated backups"
  default     = "08:00-08:34"
}

variable "maintenance_window" {
  type        = string
  description = "Weekly time range (in UTC) for scheduled/system maintenance"
  default     = "Sun:08:34-Sun:09:08"
}

variable "auto_minor_upgrades" {
  type        = bool
  description = <<EOM
Whether or not to perform minor engine upgrades automatically during the
specified in the maintenance window. Defaults to false.
EOM
  default     = false
}

variable "major_upgrades" {
  type        = bool
  description = <<EOM
Whether or not to allow performing major version upgrades when
changing engine versions. Defaults to true.
EOM
  default     = true
}

variable "apg_cluster_pgroup_params" {
  type = list(object({
    name   = string
    value  = string
    method = string
  }))
  description = <<EOM
List of parameters to configure for the AuroraDB cluster parameter group.
Include name, value, and apply method (will default to 'immediate' if not set).
EOM
  default     = []
}

variable "apg_db_pgroup_params" {
  type = list(object({
    name   = string
    value  = string
    method = string
  }))
  description = <<EOM
List of parameters to configure for the AuroraDB instance parameter group.
Include name, value, and apply method (will default to 'immediate' if not set).
EOM
  default     = []
}

# Networking

variable "db_subnet_group" {
  type        = string
  description = <<EOM
(OPTIONAL) Name of private subnet group in the var.region VPC. If left empty,
will generate aws_db_subnet_group.db resource and use that.
EOM
  default     = ""
}

variable "db_subnet_ids" {
  type        = list(string)
  description = <<EOM
(OPTIONAL) List of private subnet IDs in the var.region VPC. If left empty,
will generate aws_subnet.db* resources and use those.
EOM
  default     = []
}

variable "db_security_group" {
  type        = string
  description = <<EOM
VPC Security Group ID used by the AuroraDB cluster. If left blank, will generate
an aws_security_group.db resource and use it instead.
EOM
  default     = ""
}

variable "ingress_security_group_ids" {
  type        = list(string)
  description = <<EOM
VPC Security Group ID used by the AuroraDB cluster. If left empty, will generate
an aws_security_group.db resource and use it instead.
EOM
  default     = []
}

variable "az_cidr_map" {
  type        = map(string)
  description = <<EOM
(OPTIONAL) Map of AZs:CIDR ranges for AuroraDB subnets. Will ignore if
var.db_subnet_ids is set (i.e. imported). REQUIRES that var.vpc_id be set, if using.
EOM  
  default = {
    "a" = "172.16.33.32/28"
    "b" = "172.16.33.48/28"
    "c" = "172.16.33.64/28"
  }
}

variable "db_vpc_id" {
  type        = string
  description = <<EOM
(OPTIONAL) ID of the VPC in which to create the aws_subnet.db* resources. Will ignore
if var.db_subnet_ids is set; REQUIRED if using var.az_cidr_map.
EOM
  default     = ""
}

variable "db_security_groups" {
  type        = list(string)
  description = "List of VPC Security Group IDs used by the AuroraDB cluster"
  default     = []
}

#Engine Information

variable "storage_encrypted" {
  description = "Specifies whether the underlying Aurora storage layer should be encrypted"
  type        = bool
  default     = true
}

variable "replica_scale_enabled" {
  description = "Whether to enable autoscaling for Aurora read replica auto scaling"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default = {
    Name = "aurora-db"
  }
}

#monitoring

variable "performance_insights_enabled" {
  default     = "true"
  description = "Enables Performance Insights on RDS"
}

variable "rds_enhanced_monitoring_interval" {
  description = "How many seconds to wait before each metric sample collection - Set to 0 to disable"
  type        = number
  default     = 60
}

variable "rds_monitoring_role_name" {
  default = "rds-monitoring-role"
}

variable "enable_postgresql_log" {
  description = "Enable PostgreSQL log export to Amazon Cloudwatch."
  type        = bool
  default     = true
}

# DNS records
variable "aurora_writer_dns" {
  description = "Route53 dns record prefix  for the Writer endpoint of Aurora Cluster."
  type        = string
}

variable "aurora_reader_dns" {
  description = "Route53 dns record prefix  for the Reader endpoint of Aurora Cluster."
  type        = string
}

variable "key_admin_role_name" {
  type        = string
  description = <<EOM
Name of the IAM role to be granted permissions to interact with the KMS key
used for encrypting the database.
EOM
}