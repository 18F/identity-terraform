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
      "${aws_cloudwatch_log_group.snow_incident_lambda.arn}:*"
    ]
  }
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.snow_parameter_base}/snow_username",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.snow_parameter_base}/snow_password"
    ]
  }
}

# Default CW encryption is adequate for this low-impact Lambda
# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "snow_incident_lambda" {
  name              = "/aws/lambda/${var.name}_snow_incident"
  retention_in_days = 365
}

resource "aws_ssm_parameter" "snow_username" {
  name        = "${var.snow_parameter_base}/snow_username"
  type        = "String"
  description = "ServiceNow basic auth username"
  value       = "REPLACE_ME"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "snow_password" {
  name        = "${var.snow_parameter_base}/snow_password"
  type        = "SecureString"
  description = "ServiceNow basic auth password"
  value       = "REPLACE_ME"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_iam_role" "snow_incident_lambda" {
  name_prefix        = "${var.name}_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "snow_incident_lambda" {
  name   = "${var.name}_lambda"
  role   = aws_iam_role.snow_incident_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "snow_incident_lambda_execution_role" {
  role       = aws_iam_role.snow_incident_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/snow_incident.py"
  output_path = "${path.module}/src/snow_incident.zip"
}

# Ignore missing XRay warning
# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "snow_incident" {
  description      = "Managed by Terraform"
  filename         = "${path.module}/src/snow_incident.zip"
  function_name    = var.name
  handler          = "snow_incident.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = false
  role             = aws_iam_role.snow_incident_lambda.arn
  runtime          = var.lambda_runtime
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      SNOW_INCIDENT_URL   = var.snow_incident_url,
      SNOW_CALLER_ID      = var.snow_caller_id,
      SNOW_CATEGORY_ID    = var.snow_category_id,
      SNOW_SUBCATEGORY_ID = var.snow_subcategory_id,
      SNOW_ITEM_ID        = var.snow_item_id,
      SNOW_PARAMETER_BASE = var.snow_parameter_base
    }
  }
}

# This SNS topic is never used for sensitive information
# tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "snow_incident" {
  name = var.topic_name
}

resource "aws_lambda_permission" "allow_sns_trigger" {
  statement_id  = "AllowExecutionBySNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snow_incident.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.snow_incident.arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.snow_incident.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.snow_incident.arn
}
