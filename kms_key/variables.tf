variable "env_name" {
    description = "Environment Name"
}

variable "key_description" {
    description = "KMS key description"
}

variable "key_alias" {
    description = "KMS key alias. The environment name will be a prefix in the form of environment/"
}