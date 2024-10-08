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
  default     = []
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

variable "error_rate_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "memory_usage_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "duration_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}

variable "error_rate_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for error rate alarm"
  default     = ""
}

variable "memory_usage_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for memory usage alarm"
  default     = ""
}

variable "duration_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for duration alarm"
  default     = ""
}

locals {
  duration_settings_in_milliseconds      = var.duration_setting * 1000
  default_error_rate_alarm_description   = "Lambda error rate has exceeded ${var.error_rate_threshold}%\n\n${var.runbook}"
  default_memory_usage_alarm_description = "Lambda memory usage has exceeded ${var.memory_usage_threshold}%\n\n${var.runbook}"
  default_duration_alarm_description     = "Lambda duration has exceeded ${var.duration_threshold}%\n\n${var.runbook}"
}
