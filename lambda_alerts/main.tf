locals {
  // default descriptions
  default_lambda_error_rate_description = <<EOM
  Lambda error rate has exceeded ${var.error_rate_threshold}%
  ${var.runbook}
  EOM

  default_lambda_memory_usage_decription = <<EOM
  Lambda memory usage has exceeded ${var.memory_usage_threshold}%
  ${var.runbook}
  EOM

  default_lambda_duration_decription = <<EOM
  Lambda duration has exceeded ${var.duration_threshold}%
  ${var.runbook}
  EOM

  // overide descriptions
  override_lambda_error_rate_description = <<EOM
  One or more errors were detected running the ${var.function_name} lambda function, error rate has exceeded ${var.error_rate_threshold}%.

  ${var.runbook}
  EOM

  override_lambda_memory_usage_decription = <<EOM
  The memory used by the ${var.function_name} lambda function, exceeded ${var.error_rate_threshold}% of the AWS.

  ${var.runbook}
  EOM

  override_lambda_duration_decription = <<EOM
  The runtime of the ${var.function_name} lambda function exceeded ${var.duration_threshold}% of the AWS maximum runtime limit of 15 minutes.

  ${var.runbook}
  EOM

  lambda_error_rate_description   = length(var.alarm_name_override) > 0 ? local.override_lambda_error_rate_description : local.default_lambda_error_rate_description
  lambda_memory_usage_description = length(var.alarm_name_override) > 0 ? local.override_lambda_memory_usage_decription : local.default_lambda_memory_usage_decription
  lambda_duration_description     = length(var.alarm_name_override) > 0 ? local.override_lambda_duration_decription : local.default_lambda_duration_decription
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count = var.enabled

  alarm_name = length(var.alarm_name_override) > 0 ? "${var.alarm_name_override}-errorDetected" : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaErrorRate"
    ])
  )

  alarm_description = local.lambda_error_rate_description

  comparison_operator       = var.error_rate_operator
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.error_rate_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions != "" ? var.ok_actions : null

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

  alarm_name = length(var.alarm_name_override) > 0 ? "${var.alarm_name_override}-memoryUsageHigh" : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaMemoryUsage"
    ])
  )
  alarm_description = local.lambda_memory_usage_description

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.memory_usage_threshold
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions != "" ? var.ok_actions : null

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

  alarm_name = length(var.alarm_name_override) > 0 ? "${var.alarm_name_override}-durationLong" : join("-", compact([
    var.env_name,
    var.function_name,
    "LambdaDuration"
    ])
  )
  alarm_description = local.lambda_duration_description

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = local.duration_settings_in_milliseconds * (var.duration_threshold * 0.01)
  insufficient_data_actions = []
  datapoints_to_alarm       = var.datapoints_to_alarm
  treat_missing_data        = var.treat_missing_data
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions != "" ? var.ok_actions : null

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
