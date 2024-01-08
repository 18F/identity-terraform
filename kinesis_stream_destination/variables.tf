# Locals

locals {
  identifier_name = var.role_name == "" ? (
  "cloudwatch-to-kinesis-${local.region}") : var.role_name
  dest_acct_id  = data.aws_caller_identity.current.account_id
  region        = data.aws_region.current.name
  stream_region = var.stream_region == "" ? local.region : var.stream_region
}

# Variables

variable "stream_arn" {
  type        = string
  description = "ARN of the Kinesis Data Stream that the Destination points to."
}

variable "stream_region" {
  type        = string
  description = <<EOM
Region where the Kinesis Data Stream is located. If not specified,
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
CloudWatch Logs for accessing Kinesis Data Stream/CloudWatch Destinations,
and the name of the CloudWatch Destination itself.
Will default to "cloudwatch-to-kinesis-`local.region`" if not set.
EOM
  default     = ""
}
