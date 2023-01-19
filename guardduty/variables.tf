# Locals

locals {
  gd_perm_conditions = [
    {
      "variable" = "aws:SourceAccount",
      "values"   = [data.aws_caller_identity.current.account_id]
    },
    {
      "variable" = "aws:SourceArn",
      "values"   = [aws_guardduty_detector.main.arn]
    }
  ]
  bucket_name_suffix = "${data.aws_caller_identity.current.account_id}-${var.region}"
  log_bucket = var.log_bucket_name != "" ? (
    var.log_bucket_name) : join(".",
    [var.bucket_name_prefix, "s3-access-logs", local.bucket_name_suffix]
  )
  inventory_bucket = var.inventory_bucket_name != "" ? (
    var.inventory_bucket_name) : join(".",
    [var.bucket_name_prefix, "s3-inventory", local.bucket_name_suffix]
  )
}

# Variables

variable "region" {
  default = "us-west-2"
}

variable "bucket_name_prefix" {
  description = <<EOM
REQUIRED. First substring in S3 bucket name of
$bucket_name_prefix.$env_name-guardduty.$account_id-$region
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

variable "finding_freq" {
  type        = string
  description = "Frequency of notifications for GuardDuty findings."
  default     = "SIX_HOURS"
}

variable "s3_enable" {
  type        = bool
  description = "Whether or not to enable S3 protection in GuardDuty."
  default     = false
}

variable "k8s_audit_enable" {
  type        = bool
  description = <<EOM
Whether or not to enable Kubernetes audit logs as a data source
for Kubernetes protection (via GuardDuty).
EOM
  default     = false
}

variable "ec2_ebs_enable" {
  type        = bool
  description = <<EOM
Whether or not to enable Malware Protection (via scanning EBS volumes)
as a data source for EC2 instances (via GuardDuty).
EOM
  default     = false
}
