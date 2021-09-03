variable "domain_name" {
  description = "The primary name used on the issued TLS certificate"
}

variable "subject_alternative_names" {
  default     = []
  description = "A list of additional names to add to the certificate"
}

variable "validation_zone_id" {
  description = "Zone ID used to create the validation CNAMEs"
}

variable "validation_cname_ttl" {
  default = 300
}
