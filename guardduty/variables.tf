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
  inventory_bucket_arn = var.inventory_bucket_arn != "" ? (
    var.inventory_bucket_arn) : join(".",
    ["arn:aws:s3:::${var.bucket_name_prefix}", "s3-inventory", local.bucket_name_suffix]
  )
}

# Variables

variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "bucket_name" {
  type        = string
  description = <<EOM
Second substring in S3 bucket name of
$bucket_name_prefix.$bucket_name.$account_id-$region.
EOM
  default     = "guardduty"
}

variable "bucket_name_prefix" {
  type        = string
  description = <<EOM
First substring in S3 bucket name of
$bucket_name_prefix.$bucket_name.$account_id-$region.
EOM
}

variable "bucket_name_override" {
  type        = string
  description = "Set this to override the normal bucket naming schema."
  default     = ""
}

variable "log_bucket_name" {
  type        = string
  description = <<EOM
Override name of the bucket used for S3 logging.
Will default to $bucket_name_prefix.s3-access-logs.$account_id-$region
if not explicitly declared.
EOM
  default     = ""
}

variable "inventory_bucket_arn" {
  type        = string
  description = <<EOM
Override ARN of the S3 Inventory reports bucket.
Defaults to arn:aws:s3:::$bucket_name_prefix.s3-inventory.$account_id-$region
if not explicitly declared.
EOM
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

variable "event_rule_name" {
  type        = string
  description = "Name for the GuardDuty Findings CloudWatch Event Rule."
  default     = "GuardDutyFindings"
}

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch Log Group to log GuardDuty findings."
  default     = "/aws/events/gdfindings"
}

variable "event_target_id" {
  type        = string
  description = "ID for the Event Target used for CloudWatch Logs."
  default     = "SendToCWLogGroup"
}

