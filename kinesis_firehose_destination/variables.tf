# Locals

locals {
  identifier_name = var.role_name == "" ? (
  "cloudwatch-to-firehose-${local.region}") : var.role_name
  dest_acct_id    = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  firehose_region = var.firehose_region == "" ? local.region : var.firehose_region
}

# Variables

variable "firehose_arn" {
  type        = string
  description = "ARN of the Kinesis Data Firehose that the Destination points to."
}

variable "firehose_region" {
  type        = string
  description = <<EOM
Region where the Kinesis Data Firehose is located. If not specified,
defaults to data.aws_region.current.name instead.
EOM
  default     = ""
}

variable "source_account_id" {
  type        = string
  description = "ID of the AWS Account where log data will be sent FROM."
}

variable "role_name" {
  type        = string
  description = <<EOM
Identifier string used to name the IAM role/policies used by
CloudWatch Logs for accessing Kinesis Data Firehose/CloudWatch Destinations,
and the name of the CloudWatch Destination itself.
Will default to "cloudwatch-to-firehose-`local.region`" if not set.
EOM
  default     = ""
}
