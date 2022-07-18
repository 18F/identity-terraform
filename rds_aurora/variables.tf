# Locals

locals {
  db_name    = "${var.name_prefix}-${var.env_name}-${var.db_identifier}-${var.region}"
  db_subnets = var.db_subnet_ids == [] ? {} : var.az_cidr_map
  pgroup_family = join("", [
    var.db_engine,
    can(regex(
      "postgresql", var.db_engine
    )) ? split(".", var.db_engine_version)[0] : regex("\\d+\\.\\d+", var.db_engine_version)
  ])

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

variable "db_identifier" {
  type        = string
  description = "Unique identifier for the database, e.g. default, master"
}

variable "rds_db_arn" {
  type        = string
  description = <<EOM
(OPTIONAL) ARN of RDS DB used as replication source for the Aurora cluster.
Leave blank if not using an RDS replication source / creating a standalone cluster. 
EOM
  default     = ""
}

# Read Replicas / Autoscaling

variable "primary_cluster_instances" {
  type        = number
  description = <<EOM
Number of instances to create for the primary AuroraDB cluster. MUST be Set to 1
if creating cluster as a read replica, then should be set to 2+ thereafter.
EOM
  default     = 2
}

variable "enable_autoscaling" {
  type        = bool
  description = "Whether or not to enable Autoscaling of read replica instances"
  default     = false
}

variable "max_cluster_instances" {
  type        = number
  description = <<EOM
Maximum number of read replica instances to scale up to,
if enabling Application AutoScaling for the Aurora cluster.
EOM
  default     = 5
}

variable "autoscaling_metric_name" {
  type        = string
  description = "Name of the predefined metric used by the Autoscaling policy."
  default     = ""

  validation {
    condition = var.autoscaling_metric_name == "" || contains(
      [
        "RDSReaderAverageCPUUtilization", "RDSReaderAverageDatabaseConnections"
    ], var.autoscaling_metric_name)
    error_message = <<EOM
var.autoscaling_metric_name must be left blank, or be one of:
RDSReaderAverageCPUUtilization, RDSReaderAverageDatabaseConnections
EOM
  }
}

variable "autoscaling_metric_value" {
  type        = number
  description = "Desired target value of Autoscaling policy's predefined metric."
  default     = 40
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
var.db_subnet_ids is set (i.e. imported). REQUIRES that db_vpc_id be set, if using.
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

# Security/KMS

variable "storage_encrypted" {
  type        = bool
  description = "Whether or not to encrypt the underlying Aurora storage layer"
  default     = true
}

variable "db_kms_key_id" {
  type        = string
  description = <<EOM
(OPTIONAL) ID of an already-existing KMS Key used to encrypt the database.
If left blank, will create the aws_kms_key.db resource and use that for encryption.
EOM
  default     = ""
}

variable "key_admin_role_name" {
  type        = string
  description = <<EOM
(REQUIRED) Name of an external IAM role to be granted permissions to interact with
the KMS key used for encrypting the database.
EOM
}

variable "rds_password" {
  type        = string
  description = "Password for the RDS master user account"
}

variable "rds_username" {
  type        = string
  description = "Username for the RDS master user account"
}

# Monitoring

variable "pi_enabled" {
  type        = bool
  description = "Whether or not to enable Performance Insights on the Aurora cluster"
  default     = true
}

variable "monitoring_interval" {
  type        = number
  description = <<EOM
Time (in seconds) to wait before each metric sample collection.
Disabled if set to 0.
EOM
  default     = 60
}

variable "monitoring_role" {
  type        = string
  description = <<EOM
(OPTIONAL) Name of an existing IAM role with the AmazonRDSEnhancedMonitoringRole
service role policy attached. If left blank, will create the rds_monitoring IAM role
(which has said permission) within the module.
EOM
  default     = ""
}

# DNS / Route53

variable "internal_zone_id" {
  type        = string
  description = <<EOM
ID of the Route53 hosted zone to create records in. Leave blank
if not configuring DNS/Route53 records for the Aurora cluster/instances.
EOM
  default     = ""
}

variable "route53_ttl" {
  type        = number
  description = "TTL for the Route53 DNS records for the writer/reader endpoints."
  default     = 300
}
