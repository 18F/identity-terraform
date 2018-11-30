variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS Region"
}

variable "secret_name" {
    description = "Name of secret"
}

variable "secret_description" {
    description = "Description of secret"
}

variable "secret_kms_key_id" {
    description = "KMS key used to encrypt secret"
    default = "alias/aws/secretsmanager"
}

variable "secret_recovery_window" {
    description = "Number of days secrets manager waits to delete secret.  0 force deletion or range from 7 to 30"
    default = "30"
}
    
variable "secret_rotation_days" {
    description = "Number of days between secret rotation"
    default = "15"
}

variable "lambda_source_bucket" {
    description = "Lambda source bucket name"
}

variable "password_rotation_lambda_source_key" {
    description = "Path in S3 bucket to lambda function example: kinesis/events_transform.zip"
}

variable "password_rotation_lambda_name" {
    description = "Name for rotation lambda"
}

variable "password_rotation_lambda_memory" {
    description = "Amount of RAM to assign to lambda function min 128 max 3008 in 64mb increments"
    default = "128"
}

variable "password_rotation_lambda_timeout" {
    description = "Lambda timeout"
    default = "120"
}

variable "password_rotation_lambda_handler" {
    description = "Handler function name"
}

variable "password_rotation_lambda_runtime" {
    description = "Lambda runtime"
    default = "python2.7"
}

variable "password_rotation_lambda_vpc_id" {
    description = "Lambda VPC ID"
}

variable "password_rotation_lambda_subnets" {
    description = "List of VPC subnets for lambda"
    type = "list"
}
