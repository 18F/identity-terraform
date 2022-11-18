# Locals

locals {
  guardduty_feedname_iam = replace(
    var.guardduty_threat_feed_name,
    "/[^a-zA-Z0-9 ]/", ""
  )
  gd_s3_bucket = join(".", [
    var.bucket_name_prefix,
    ".gd-${var.guardduty_threat_feed_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

# Variables

variable "guardduty_threat_feed_name" {
  description = "Name of the GuardDuty threat feed, used to name other resources"
  type        = string
  default     = "gd-threat-feed"
}

variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
}

variable "region" {
  description = "AWS Region"
}

variable "guardduty_days_requested" {
  type    = number
  default = 7
}

variable "guardduty_frequency" {
  type    = number
  default = 6
}

variable "guardduty_threat_feed_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/guard-duty-threat-feed.zip"
}

variable "logs_bucket" {
  description = "Name of the bucket to store access logs in"
}

variable "inventory_bucket_arn" {
  description = "ARN of the bucket used for S3 Inventory"
}
