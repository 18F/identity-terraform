variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS region"
}

variable "stream_name" {
    description = "Firehose delivery stream name"
}

variable "datastream_source_arn" {
    description = "Kinesis datastream source arn"
}

variable "redshift_jdbc" {
    description = "Redshift jdbc connection"
}

variable "redshift_username" {
    description = "Redshift database user"
}

variable "redshift_password" {
    description = "Redshift database password"
}

variable "redshift_table" {
    description = "Redshift table"
}

variable "copy_options" {
    description = "Copy options for Redshift"
}

variable "columns" {
    description = "Comma separated list of columns for copy"
}

variable "lambda_arn" {
    description = "Transformation Lambda arn"
}

variable "s3_intermediate_bucket_arn" {
    description = "S3 bucket arn for intermediate storage"
}

variable "s3_intermediate_bucket_prefix" {
    description = "Prefix for S3 intermediate bucket"
}

variable "s3_temp_key_arn" {
    description = "KMS key arn for S3 bucket backup/intermediate bucket"
}

variable "stream_key_arn" {
    description = "KMS key arn for source datastream"
}

variable "buffer_size" {
    description = "Amount of data in mb to buffer before writing to S3 values between 1 and 128"
    default = "1"
}

variable "buffer_interval" {
    description = "Amount of time in seconds to wait before writing to S3 values between 60 and 900"
    default = "60"
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