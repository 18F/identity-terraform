variable "function_enabled" {
  description = "Whether or not to enable the function"
  default     = 1
}

variable "function_name" {
  description = "Name of the lambda function to monitor"
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarm fires"
}

variable "error_rate_threshold" {
  description = "The threshold error rate (as a percentage) for triggering an alert"
  default     = 1
}

variable "datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm."
  default     = 1
}

variable "evaluation_periods" {
  default = 1
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied."
  default     = 60
}

variable "treat_missing_data" {
  default = "missing"
}

resource "aws_cloudwatch_metric_alarm" "elb_http_5xx" {
  alarm_name        = "Lambda error rate: ${var.function_name}"
  alarm_description = "Lambda error rate has exceeded ${var.error_rate_threshold}%"

  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods        = var.evaluation_periods
  threshold                 = var.error_rate_threshold
  insufficient_data_actions = []

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

  datapoints_to_alarm = var.datapoints_to_alarm

  treat_missing_data = var.treat_missing_data

  alarm_actions = var.alarm_actions
}

