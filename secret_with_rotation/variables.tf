variable "env_name" {
    description = "Environment Name"
}

variable "secret_name" {
    description = "Name of secret"
}

variable "secret_description" {
    description = "Description of secret"
}

variable "secret_rotation_lambda_arn" {
    description = "Secret rotation lambda arn"
}

variable "secret_kms_key_id" {
    description = "KMS key used to encrypt secret"
    default = "aws/secretsmanager"
}

variable "secret_recovery_window" {
    description = "Number of days secrets manager waits to delete secret.  0 force deletion or range from 7 to 30"
    default = "30"
}
    
variable "secret_rotation_days" {
    description = "Number of days between secret rotation"
    default = "15"
}