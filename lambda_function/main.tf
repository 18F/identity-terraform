module "lambda_insights" {
  count  = var.insights_enabled ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_insights?ref=5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9"
  #source = "../../../../identity-terraform/lambda_insights"

  region = var.region
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.log_skip_destroy
}

module "lambda_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=2d05076e1d089d9e9ab251fa0f11a2e2ceb132a3"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = var.source_code_filename
  source_dir           = var.source_dir
  zip_filename         = "${replace(var.function_name, "-", "_")}_code.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = module.lambda_code.zip_output_path
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  description   = var.description
  handler = var.handler != "" ? (
    var.handler
    ) : (
    "${replace(var.source_code_filename, "/\\..*/", "")}.${var.handler_function_name}"
  )

  source_code_hash               = module.lambda_code.zip_output_base64sha256
  memory_size                    = var.memory_size
  runtime                        = var.runtime
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  layers = compact(flatten([
    var.insights_enabled ? module.lambda_insights[0].layer_arn : "",
    var.layers
  ]))

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  depends_on = [
    module.lambda_code.resource_check,
  ]
}

module "lambda_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../../../../identity-terraform/lambda_alerts"

  enabled                          = var.enabled
  function_name                    = aws_lambda_function.lambda.function_name
  env_name                         = var.env_name
  alarm_actions                    = var.alarm_actions
  ok_actions                       = var.ok_actions
  runbook                          = var.runbook
  error_rate_operator              = var.error_rate_operator
  error_rate_threshold             = var.error_rate_threshold
  memory_usage_threshold           = var.memory_usage_threshold
  duration_setting                 = aws_lambda_function.lambda.timeout
  duration_threshold               = var.duration_setting
  datapoints_to_alarm              = var.datapoints_to_alarm
  evaluation_periods               = var.evaluation_periods
  period                           = var.period
  treat_missing_data               = var.treat_missing_data
  insights_enabled                 = var.insights_enabled
  error_rate_alarm_name_override   = var.error_rate_alarm_name_override
  memory_usage_alarm_name_override = var.memory_usage_alarm_name_override
  duration_alarm_name_override     = var.duration_alarm_name_override
  error_rate_alarm_description     = var.error_rate_alarm_description
  memory_usage_alarm_description   = var.memory_usage_alarm_description
  duration_alarm_description       = var.duration_alarm_description
}
