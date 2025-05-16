locals {
  log_group_name = var.log_group_name_override == "" ? "${var.env_name}_/var/log/squid/access.log" : var.log_group_name_override
  alarm_environment = var.env_type != "" ? (
    "${var.env_name}-${var.env_type}"
  ) : var.env_name
}

variable "env_name" {
  type        = string
  description = "Environment name, for prefixing the generated metric names"
}

variable "env_type" {
  type        = string
  description = "Environment type, for prefixing the generated alarm names"
  default     = ""
}

variable "log_group_name_override" {
  type        = string
  description = "The name of the log group, overriding the default <env_name>_/var/log/squid/access.log"
  default     = ""
}

variable "metric_namespace" {
  type        = string
  description = "Namespace to use for created cloudwatch metrics"
  default     = "LogMetrics/squid"
}

variable "treat_missing_data" {
  type        = string
  description = "How to treat missing metric data in the denials alarm."
  default     = "notBreaching"
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the squid denied alarm fires"
}

variable "runbook_url" {
  type        = string
  description = "A URL to a runbook to help triage alerts"
}

