variable "bucket_name" {
    description = "S3 Bucket Name"
}

variable "versioning_enabled" {
    description = "S3 Versioning Enabled"
    default = false
}

variable "region" {
    description = "AWS Region"
    default = "us-west-2"
}

variable "env_name" {
    description = "Environment Name"
}