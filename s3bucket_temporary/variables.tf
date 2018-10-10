variable "region" {
    description = "AWS Region"
    default = "us-west-2"
}

variable "env_name" {
    description = "Environment Name"
}

variable "bucket_name" {
    description = "S3 Bucket Name"
}

variable "kms_key_id" {
    description = "KMS key id for bucket encryption"
}

