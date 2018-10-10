variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS region"
}

variable "stream_name" {
    description = "Firehose delivery stream name"
}

variable "redshift_jdbc" {
    description = "Redshift jdbc connection"
}

variable "redshift_user" {
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

variable "intermediate_bucket_arn" {
    description = "S3 bucket arn for intermediate storage"
}

variable "kms_key_arn" {
    description = "KMS key arn for S3 bucket encryption"
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