variable "ssm_doc_map" {
  description = <<EOM
REQUIRED. Map of data for SSM Documents. Each must include the document name,
description, command(s) to run at login, whether to log the commands/output from the
given session/document, and whether to run specifically as root (vs. a Linux user).
EOM
  type        = map(map(string))
  default = {
    "default" = {
      description = "Login shell"
      command     = "cd ; /bin/bash"
      logging     = false
      use_root    = false
    },
  }
}

variable "ssm_cmd_doc_map" {
  description = <<EOM
REQUIRED. Map of data for SSM Documents. Each must include the document name,
description, command(s) to run at login, whether to log the commands/output from the
given session/document, and whether to run specifically as root (vs. a Linux user).
EOM
  type        = map(map(string))
  default = {
    "default" = {
      description = "Login shell"
      command     = "uptime"
      logging     = false
      use_root    = false
    },
  }
}

variable "session_timeout" {
  description = <<EOM
REQUIRED. Amount of time (in minutes) of inactivity
to allow before a session ends.
EOM
  type        = number
  default     = 15
}

variable "region" {
  description = "REQUIRED. AWS Region"
  type        = string
}

variable "env_name" {
  description = "REQUIRED. Environment name"
  type        = string
}

variable "bucket_name_prefix" {
  description = <<EOM
REQUIRED. First substring in S3 bucket name of
$bucket_name_prefix.$env_name-ssm-logs.$account_id-$region
EOM
  type        = string
}

variable "log_bucket_name" {
  description = <<EOM
(OPTIONAL) Override name of the bucket used for S3 logging.
Will default to $bucket_name_prefix.s3-access-logs.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

variable "inventory_bucket_name" {
  description = <<EOM
(OPTIONAL) Override name of the S3 bucket used for S3 Inventory reports.
Will default to $bucket_name_prefix.s3-inventory.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

locals {
  bucket_name_suffix = "${data.aws_caller_identity.current.account_id}-${var.region}"
  s3_bucket_name     = "${var.bucket_name_prefix}.${var.env_name}-ssm-logs.${local.bucket_name_suffix}"

  log_bucket = var.log_bucket_name != "" ? var.log_bucket_name : join(".",
    [var.bucket_name_prefix, "s3-access-logs", local.bucket_name_suffix]
  )

  inventory_bucket = var.inventory_bucket_name != "" ? var.inventory_bucket_name : join(".",
    [var.bucket_name_prefix, "s3-inventory", local.bucket_name_suffix]
  )
}
