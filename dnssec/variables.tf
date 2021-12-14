variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

variable "dnssec_ksk_max_days" {
  description = "Maxium age of DNSSEC KSK before alerting due to being too old"
  type        = number
  default     = 366
}

variable "dnssec_ksks" {
  description = "Map of Key Signing Keys (KSKs) to provision for each zone"
  # See key rotation notes in the README for more info here
  type = map(string)
  default = {
    # "2111005" = "old",
    "20211006" = "active"
  }
}

variable "dnssec_zone_name" {
  description = "Name of the Route53 DNS domain to to apply DNSSEC configuration to."
  type        = string
}

variable "dnssec_zone_id" {
  description = "ID of the Route53 DNS domain to to apply DNSSEC configuration to."
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
  default = true
}