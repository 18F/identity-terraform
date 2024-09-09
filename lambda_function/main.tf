module "lambda_insights" {
  count  = var.insights_enabled
  source = "github.com/18F/identity-terraform//lambda_insights?ref=5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9"
  #source = "../../../../identity-terraform/lambda_insights"

  region = var.region
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = false
}

module "lambda_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
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
  handler       = "${replace(var.function_name, "-", "_")}.${var.handler}"

  source_code_hash = module.lambda_code.zip_output_base64sha256
  memory_size      = var.memory_size
  runtime          = var.runtime
  timeout          = var.timeout

  layers = compact([
    var.insights_enabled == 1 ? module.lambda_insights[0].layer_arn : ""
  ])

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.arn
  }

  depends_on = [
    module.lambda_code.resource_check,
  ]
}

module "lambda_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b4c39660e888c87e56fb910cca3104bd6a12b093"
  #source = "../../../../identity-terraform/lambda_alerts"

  function_name      = aws_lambda_function.lambda.function_name
  alarm_actions      = var.alarm_actions
  insights_enabled   = true
  duration_setting   = aws_lambda_function.lambda.timeout
  treat_missing_data = var.treat_missing_data
}
