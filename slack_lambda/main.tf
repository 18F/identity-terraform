# -- Data Sources --

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
      "${aws_cloudwatch_log_group.slack_lambda.arn}:*"
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
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.slack_webhook_url_parameter}"
    ]
  }
}

# -- Resources --

resource "aws_cloudwatch_log_group" "slack_lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
}

module "slack_lambda" {
  source = "github.com/18F/identity-terraform//null_lambda?ref=fe70f9e07b70d1a27b7e9587a800e05711bdf5c3"
  #source = "../identity-terraform/null_lambda"

  source_code_filename  = "lambda_function.py"
  source_dir            = "${path.module}/src/"
  zip_filename          = "lambda_function"
  external_role_arn     = aws_iam_role.slack_lambda.arn
  function_name         = var.lambda_name
  description           = var.lambda_description
  handler               = "lambda_function.lambda_handler"
  memory_size           = var.lambda_memory
  runtime               = "python3.8"
  timeout               = var.lambda_timeout
  perm_id               = "AllowExecutionBySNS"
  permission_principal  = ["sns.amazonaws.com"]
  permission_source_arn = var.slack_topic_arn

  env_var_map = {
    slack_webhook_url_parameter = var.slack_webhook_url_parameter
    slack_channel               = var.slack_channel,
    slack_username              = var.slack_username,
    slack_icon                  = var.slack_icon
  }
}

resource "aws_iam_role" "slack_lambda" {
  name_prefix        = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "slack_lambda" {
  name   = var.lambda_name
  role   = aws_iam_role.slack_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = var.slack_topic_arn
  protocol  = "lambda"
  endpoint  = module.slack_lambda.lambda_arn
}
