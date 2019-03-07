variable "env_name" {
  description = "Environment name"
}

variable "region" {
  default = "us-west-2"
  description = "AWS Region"
}

variable "kmslogging_service_enabled" {
  default = 0
  description = "Enable KMS Logging service.  If disabled the CloudWatch rule will not be created."
}

variable "kinesis_shard_count" {
  default = 1
  description = "Number of shards to allocate to Kinesis data stream"
}

variable "kinesis_retention_hours" {
  default = 24
  description = "Number of hours to retain data in Kinesis data stream.  Max = 168"
}

variable "cloudwatch_filter_pattern" {
  default = "[type, datetime, info, whitespace, json = *pii-encryption* || json = *password-digest*]"
  description = "Filter pattern for CloudWatch kms.log file"
}