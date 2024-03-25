variable "env_name" {
  description = "Environment name, for prefixing the generated metric names"
}

variable "log_group_name_override" {
  default     = ""
  description = "The name of the log group, overriding the default <env_name>_/var/log/squid/access.log"
}

variable "metric_namespace" {
  description = "Namespace to use for created cloudwatch metrics"
  default     = "LogMetrics/squid"
}

variable "treat_missing_data" {
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

variable "slack_handles" {
  type        = list(any)
  description = "A list of Slack group handles to tag in the alarm description"
}
