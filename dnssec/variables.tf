variable "dnssec_alarms" {
  description = "Data for any desired DNSSEC / KSK alarms in CloudWatch (if creating)"
  type        = any
  default     = {
    "dnssec_alarm_example" = {
      desc          = "ZONEID DNSSEC Alarm"
      metric_name   = "MetricName"
      statistic     = "Sum"
      comp_operator = "GreaterThanThreshold"
      statistic     = 0
      period        = 86400
      eval_periods  = 1
    }
  }
}

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
