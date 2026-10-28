locals {
  enable_trigger = (
    var.schedule_expression == "" && var.event_pattern != "") || (
  var.schedule_expression != "" && var.event_pattern == "")
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  region            = var.region
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.log_skip_destroy
}

resource "aws_cloudwatch_event_rule" "lambda" {
  count = local.enable_trigger ? 1 : 0

  name                = var.function_name
  region              = var.region
  description         = "Trigger ${var.function_name} from EventBridge"
  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = local.enable_trigger ? 1 : 0

  region = var.region
  rule   = aws_cloudwatch_event_rule.lambda[0].name
  arn    = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "lambda" {
  count = local.enable_trigger ? 1 : 0

  region        = var.region
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda[0].arn
}

module "lambda_alerts" {
  count  = var.lambda_alerts_enabled ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=812c086fa4f4a0a52c1b8b630a27af01f18cf357"
  #source = "../../../../identity-terraform/lambda_alerts"

  region                           = var.region
  function_name                    = aws_lambda_function.lambda.function_name
  env_name                         = var.env_name
  alarm_actions                    = var.alarm_actions
  ok_actions                       = var.ok_actions
  runbook                          = var.runbook
  error_rate_operator              = var.error_rate_operator
  error_rate_threshold             = var.error_rate_threshold
  memory_usage_threshold           = var.memory_usage_threshold
  duration_setting                 = aws_lambda_function.lambda.timeout
  duration_threshold               = var.duration_threshold
  datapoints_to_alarm              = var.datapoints_to_alarm
  evaluation_periods               = var.evaluation_periods
  period                           = var.period
  treat_missing_data               = var.treat_missing_data
  insights_layer_enabled           = var.insights_layer_enabled
  error_rate_alarm_name_override   = var.error_rate_alarm_name_override
  memory_usage_alarm_name_override = var.memory_usage_alarm_name_override
  duration_alarm_name_override     = var.duration_alarm_name_override
  error_rate_alarm_description     = var.error_rate_alarm_description
  memory_usage_alarm_description   = var.memory_usage_alarm_description
  duration_alarm_description       = var.duration_alarm_description
}
