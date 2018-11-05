variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS region"
}

variable "stream_name" {
    description = "Firehose name"
}

variable "datastream_source_arn" {
    description = "Kinesis datastream source arn"
}

variable "firehose_bucket_arn" {
    description = "S3 Bucket arn for firehose output"
}

variable "firehose_bucket_prefix" {
    description = "Prefix for S3 in the form of prefix/"
}

variable "s3_buffer_size" {
    description = "Amount of data in mb to buffer before writing to S3 values between 1 and 128"
    default = "1"
}

variable "s3_buffer_interval" {
    description = "Amount of time in seconds to wait before writing to S3 values between 60 and 900"
    default = "60"
}
 
variable "s3_key_arn" {
    description = "KMS Encryption Key arn for S3 bucket"
}

variable "stream_key_arn" {
    description = "KMS Encryption Key arn for datastream"
}

variable "lambda_arn" {
    description = "Arn for lambda transformation"
}

variable "lambda_buffer_size" {
    description = "Amount of data in MBs to buffer prior to calling transformation lambda value between 1 and 3"
    default = "2"
}

variable "lambda_buffer_interval" {
    description = "Amount of time in seconds to elapse prior to calling transformation lambda value between 60 and 900"
    default = "120"
}

variable "s3_backup_bucket_arn" {
    description = "Arn for s3 backup"
}

variable "s3_backup_bucket_prefix" {
    description = "Prefix for S3 backup bucket"
}

variable "log_retention_in_days" {
    description = "Number of days to retain CloudWatch log data for firehose"
    default = 365
}