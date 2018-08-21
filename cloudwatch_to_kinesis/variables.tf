variable "cloudwatch_source_account_id" {
    description = "AWS Account ID that CloudWatch log group resides in."
}

variable "cloudwatch_log_group_name" {
    description = "CloudWatch log group name that will be streamed to Kinesis."
}

variable "kinesis_destination_account_id" {
    description = "AWS Account ID that Kinesis Datastream will be created in."
}

variable "name_prefix" {
    description = "This value will prefix all resources name.  A random 8 character value will be added to this prefix."
}

variable "kinesis_shard_count" {
    description = "Shard count to use with Kinesis Datastream."
    default = 1
}

variable "kinesis_retention_hours" {
    description  = "Number of hours to retain data in Kinesis stream. (Acceptable values 24 to 168)."
    default = 24
}

variable "kinesis_kms_key_id" {
    description = "KMS Key Id used to encrypt data in Kinesis"
    default = "aws/kinesis"
}

variable "aws_kinesis_region" {
    description = "AWS region to create Kinesis Datastream in."
    default = "us-west-2"
}

variable "aws_cloudwatch_region" {
    description = "AWS region where CloudWatch log group resides."
    default = "us-west-2"
}

variable "cloudwatch_filter_pattern" {
    description = "Filter pattern for CloudWatch subscription"
    default = "{$"
}

