# Locals

locals {
  destination_name = var.firehose_name == "" ? (
  "cloudwatch-to-kinesis-${local.region}") : var.firehose_name
  dest_acct_id    = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.name
  firehose_region = var.firehose_region == "" ? local.region : var.firehose_region
  kinesis_firehose_arn = join(":", [
    "arn:aws:firehose",
    local.firehose_region,
    local.dest_acct_id,
    "deliverystream/${var.firehose_name}"
  ])
}

# Variables

variable "firehose_name" {
  type        = string
  description = "Name of the Kinesis Firehose stream where data will be sent."
}

variable "firehose_region" {
  type        = string
  description = "Region where the Kinesis Firehose stream is located."
  default     = ""
}

variable "source_account_id" {
  type        = string
  description = "ID of the AWS Account where log data will be sent FROM."
}
