terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws]
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "AllowWritesToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.windowed_slo_lambda.arn}:*"
    ]
  }

  statement {
    sid    = "ReadWriteCloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
    ]
    resources = [
      # Change this once we know what the resources are, from errors.
      "*"
    ]
  }
}

# Default CW encryption is adequate for this low-impact Lambda
# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "windowed_slo_lambda" {
  name              = "/aws/lambda/${var.name}_windowed_slo"
  retention_in_days = 365
}

resource "aws_iam_role" "windowed_slo_lambda" {
  name_prefix        = "${var.name}_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "windowed_slo_lambda" {
  name   = "${var.name}_lambda"
  role   = aws_iam_role.windowed_slo_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "windowed_slo_lambda_execution_role" {
  role       = aws_iam_role.windowed_slo_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/windowed_slo.py"
  output_path = "${path.module}/windowed_slo.zip"
}

# Ignore missing XRay warning
# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "windowed_slo" {
  description      = "Managed by Terraform"
  filename         = "${path.module}/windowed_slo.zip"
  function_name    = var.name
  handler          = "windowed_slo.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = false
  role             = aws_iam_role.windowed_slo_lambda.arn
  runtime          = var.lambda_runtime
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      WINDOW_DAYS = var.window_days
      SLI_NAMESPACE = var.sli_namespace
      LOAD_BALANCER_ARN = var.load_balancer_arn
      SLI_PREFIX = var.sli_prefix
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_one_day" {
  name                = "every-one-day"
  description         = "Fires every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_one_day" {
  rule      = "${aws_cloudwatch_event_rule.every_one_day.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.windowed_slo.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_windowed_slo" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.windowed_slo.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_one_day.arn}"
}
