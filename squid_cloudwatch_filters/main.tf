
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
  alarm_name        = "${local.alarm_environment}-squid-denials"
  alarm_description = <<EOM
The outbound proxy has denied too many outbound requests.

Runbook: ${var.runbook_url}
EOM

  namespace   = var.metric_namespace
  metric_name = "${var.env_name}/DeniedRequests"

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

resource "aws_cloudwatch_metric_alarm" "squid_total_requests" {
  alarm_name        = "${local.alarm_environment}-squid-total-requests"
  alarm_description = <<EOM
The outbound proxy throughput is below the expected volume.

Runbook: ${var.runbook_url}
EOM
  namespace         = var.metric_namespace
  metric_name       = "${var.env_name}/TotalRequests"

  statistic           = "Sum"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 2
  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 5
  treat_missing_data  = var.treat_missing_data
  alarm_actions       = var.alarm_actions
}
