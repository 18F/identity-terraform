variable "kinesis_name" {
    description = "Kinesis data stream name.  env_name will be prepended to this name."
}

variable "kinesis_shard_count" {
    description = "Shard count to use with Kinesis Datastream."
    default = 2
}

variable "kinesis_retention_hours" {
    description  = "Number of hours to retain data in Kinesis stream. (Acceptable values 24 to 168)."
    default = 24
}

variable "kinesis_kms_key_id" {
    description = "KMS Key Id used to encrypt data in Kinesis"
    default = "aws/kinesis"
}

variable "aws_cloudwatch_region" {
    description = "AWS region where CloudWatch log group resides."
    default = "us-west-2"
}

variable "cloudwatch_source_account_id" {
    description = "AWS Account ID that CloudWatch log group resides in."
}
