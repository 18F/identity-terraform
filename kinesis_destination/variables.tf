# Locals

locals {
  region       = data.aws_region.current.region
  dest_acct_id = data.aws_caller_identity.current.account_id

  identifier_name = var.role_name == "" ? (
  "cloudwatch-to-kinesis-${local.region}") : var.role_name
}

# Variables

variable "kinesis_arn" {
  type        = string
  description = <<EOM
ARN of the Kinesis resource (Firehose/Data Stream) that the Destination points to.
EOM
}

variable "source_account_ids" {
  type        = list(string)
  description = "ID(s) of the AWS Account(s) where log data will be sent FROM."
}

variable "role_name" {
  type        = string
  description = <<EOM
Identifier string used to name the IAM role/policies used by
CloudWatch Logs for accessing the Kinesis resource/CloudWatch Destinations,
and the name of the CloudWatch Destination itself.
Will default to "cloudwatch-to-kinesis-`local.region`" if not set.
EOM
  default     = ""
}
