variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS region"
}

variable "name" {
    description = "Firehose name"
}

variable "datastream_name" {
    description = "Datastream source name"
}

variable "datastream_source_arn" {
    description = "Kinesis datastream source arn"
}

variable "firehose_bucket_name" {
    description = "S3 Bucket name for firehose output"
}

variable "kms_key_id" {
    description = "KMS Encryption Key Id"
}

variable "kms_key_arn" {
    description = "KMS Encrypttion Key arn"
}

variable "lambda_transform" {
    description = "Lambda name for data transformation"
}

variable "firehose_bucket_prefix" {
    description = "Firehose S3 bucket prefix"
}

variable "lambda_arn" {
    description = "Arn for lambda transformation"
}

variable "buffer_size" {
    description = "Amount of data in mb to buffer before writing to S3 values between 1 and 128"
    default = "1"
}

variable "buffer_interval" {
    description = "Amount of time in seconds to wait before writing to S3 values between 60 and 900"
    default = "60"
}

