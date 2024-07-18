variable "enabled" {
  type        = number
  description = "Whether or not to create the Lambda alert monitor."
  default     = 1
}

variable "function_name" {
  type        = string
  description = "Name of the lambda function to monitor"
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarm fires"
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

locals {
  duration_settings_in_milliseconds = var.duration_setting * 1000
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count = var.enabled

  alarm_name        = "LambdaErrorRate_${var.function_name}"
  alarm_description = "Lambda error rate has exceeded ${var.error_rate_threshold}%"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.error_rate_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions

  metric_query {
    id          = "error_rate"
    expression  = "errors / invocations * 100"
    label       = "Error Rate"
    return_data = "true"
  }
  metric_query {
    id = "errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      dimensions = {
        FunctionName = var.function_name
      }
      period = var.period
      stat   = "Sum"
    }
  }
  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      dimensions = {
        FunctionName = var.function_name
      }
      period = var.period
      stat   = "Sum"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_memory_usage" {
  count = var.enabled == 1 && var.insights_enabled ? 1 : 0

  alarm_name        = "LambdaMemoryUsage_${var.function_name}"
  alarm_description = "Lambda memory usage has exceeded ${var.memory_usage_threshold}%"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.memory_usage_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions

  metric_name = "memory_utilization"
  namespace   = "LambdaInsights"
  period      = var.period
  statistic   = "Maximum"
  dimensions = {
    function_name = var.function_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count = var.enabled

  alarm_name        = "LambdaDuration_${var.function_name}"
  alarm_description = "Lambda duration has exceeded ${var.duration_threshold}%"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = local.duration_settings_in_milliseconds * (var.duration_threshold * 0.01)
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions

  metric_name = "Duration"
  namespace   = "AWS/Lambda"
  period      = var.period
  statistic   = "Maximum"
  dimensions = {
    FunctionName = var.function_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
