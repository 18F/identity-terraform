variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify via the CloudWatch Alarms, i.e. SNS topics."
}

variable "dnssec_ksk_max_days" {
  description = "Maximum allowed age of a DNSSEC KSK before triggering a CloudWatch alarm."
  type        = number
  default     = 366
}

variable "dnssec_ksks" {
  description = "Map of Key Signing Keys (KSKs) to provision for each hosted zone."
  # See the notes in the README for more information regarding the key rotation process!
  type = map(string)
  default = {
    # "2111005" = "old",
    "20211006" = "active"
  }
}

variable "dnssec_zone_name" {
  description = "Name of the Route53 DNS domain where DNSSEC signing will be enabled."
  type        = string
}

variable "dnssec_zone_id" {
  description = "ID of the Route53 DNS domain where DNSSEC signing will be enabled."
  type        = string
}

variable "dnssec_ksks_action_req_alarm_desc" {
  type        = string
  description = <<EOM
(Optional) Extra text for the  dnssec_ksks_action_req CloudWatch Alarm description,
i.e. link to internal documentation, help pages, etc.
EOM
}

variable "dnssec_ksk_age_alarm_desc" {
  type        = string
  description = <<EOM
(Optional) Extra text for the  dnssec_ksk_age CloudWatch Alarm description,
i.e. link to internal documentation, help pages, etc.
EOM
}

variable "dnssec_errors_alarm_desc" {
  type        = string
  description = <<EOM
(Optional) Extra text for the  dnssec_errors CloudWatch Alarm description,
i.e. link to internal documentation, help pages, etc.
EOM
}

variable "protect_resources" {
  type        = bool
  description = <<EOM
Whether or not to create the IAM policy that prevents disabling/destruction of
DNSSEC itself, the associated KSKs/KMS keys/aliases, and the Route53 Hosted Zone.
EOM
  default     = true
}