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
  default     = "breaching"
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the squid denied alarm fires"
}

locals {
  log_group_name = var.log_group_name_override == "" ? "${var.env_name}_/var/log/squid/access.log" : var.log_group_name_override
}

resource "aws_cloudwatch_log_metric_filter" "squid_requests_total" {
  name           = "${var.env_name}-squid-requests-total"
  pattern        = "" # all events
  log_group_name = local.log_group_name
  metric_transformation {
    namespace     = var.metric_namespace
    name          = "${var.env_name}/TotalRequests"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "squid_requests_denied" {
  name           = "${var.env_name}-squid-requests-denied"
  pattern        = "\"DENIED\"" # logs containing DENIED anywhere
  log_group_name = local.log_group_name
  metric_transformation {
    namespace     = var.metric_namespace
    name          = "${var.env_name}/DeniedRequests"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "squid_denied_alarm" {
  alarm_name        = "${var.env_name}-squid-denials"
  alarm_description = "(Managed by Terraform) Alarm when the Squid access log shows any denied requests"
  namespace         = var.metric_namespace
  metric_name       = "${var.env_name}/DeniedRequests"

  # alert when sum(denials) >= 1 for any 1 minute out of 15 eval periods
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 15

  treat_missing_data = var.treat_missing_data

  alarm_actions = var.alarm_actions
}

