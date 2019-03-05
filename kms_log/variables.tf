variable "env_name" {
  description = "Environment name"
}

variable "kmslogging_service_enabled" {
  default = 0
  description = "Enable KMS Logging service.  If disabled the CloudWatch rule will not be created."
}