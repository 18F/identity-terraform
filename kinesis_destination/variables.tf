# Variables

variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "kinesis_arn" {
  type        = string
  description = "ARN of the Kinesis resource (Firehose/Data Stream) that the Destination points to."
}

variable "source_account_ids" {
  type        = list(string)
  description = "ID(s) of the AWS Account(s) where log data will be sent FROM."
}

variable "role_name" {
  type        = string
  description = <<EOM
Identifier string used to name the IAM role/policies used by CloudWatch Logs for accessing the
Kinesis resource/CloudWatch Destinations, and the name of the CloudWatch Destination itself.
Passed into resources as "`var.role_name`-`var.region`".
EOM
  default     = ""
}
