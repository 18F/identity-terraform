variable "enabled" {
  type        = number
  description = "Whether or not to create the Lambda alert monitor."
  default     = 1
}

variable "function_name" {
  type        = string
  description = "Name of the lambda function to monitor"
}

variable "env_name" {
  type        = string
  description = "Name of the environment in which the lambda function lives"
  default     = ""
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarm fires"
}

variable "ok_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarm goes to ok state"
}

variable "runbook" {
  type        = string
  description = "A link to a runbook associated with any metric in this module"
  default     = ""
}

variable "error_rate_operator" {
  type        = string
  description = "The operator used to compare a calculated error rate against a threshold"
  default     = "GreaterThanOrEqualToThreshold"
}

variable "error_rate_threshold" {
  type        = number
  description = "The threshold error rate (as a percentage) for triggering an alert"
  default     = 1
}

variable "memory_usage_threshold" {
  type        = number
  description = "The threshold memory utilization (as a percentage) for triggering an alert"
  default     = 90
}

variable "duration_setting" {
  type        = number
  description = "The duration setting of the lambda to monitor (in seconds)"
}

variable "duration_threshold" {
  type        = number
  description = "The duration threshold (as a percentage) for triggering an alert"
  default     = 80
}

variable "datapoints_to_alarm" {
  type        = number
  description = "The number of datapoints that must be breaching to trigger the alarm."
  default     = 1
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied."
  default     = 60
}

variable "treat_missing_data" {
  type    = string
  default = "missing"
}

variable "insights_enabled" {
  type        = bool
  description = "Creates lambda insights specific alerts"
  default     = false
}

variable "alarm_name_override" {
  type = string
  description = "Overrides the default alarm naming convention with a custom name"
  default = ""
}
locals {
  duration_settings_in_milliseconds = var.duration_setting * 1000
}
