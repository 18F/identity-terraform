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

variable "firehose_bucket_name" {
    description = "S3 Bucket name for firehose output"
}

variable "kms_key_id" {
    description = "KMS Encryption Key Id"
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

