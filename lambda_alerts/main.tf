resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count = var.enabled

  alarm_name = length(var.error_rate_alarm_name_override) > 0 ? var.error_rate_alarm_name_override : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaErrorRate"
    ])
  )

  alarm_description         = var.error_rate_alarm_description

  comparison_operator       = var.error_rate_operator
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.error_rate_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions

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

  alarm_name = length(var.memory_usage_alarm_name_override) > 0 ? var.memory_usage_alarm_name_override : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaMemoryUsage"
    ])
  )
  alarm_description         = var.memory_usage_alarm_description

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.memory_usage_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions

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

  alarm_name = length(var.duration_alarm_name_override) > 0 ? var.duration_alarm_name_override : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaDuration"
    ])
  )
  alarm_description         = var.duration_alarm_description

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = local.duration_settings_in_milliseconds * (var.duration_threshold * 0.01)
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions

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
