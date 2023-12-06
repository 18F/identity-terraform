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

module "lambda_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=91f5c8a84c664fc5116ef970a5896c2edadff2b1"
  #source = "../null_archive"

  source_code_filename = "slack_lambda.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "slack_lambda.zip"
}

# -- Resources --

resource "aws_cloudwatch_log_group" "slack_lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "slack_lambda" {
  filename         = module.lambda_code.zip_output_path
  function_name    = var.lambda_name
  description      = var.lambda_description
  role             = aws_iam_role.slack_lambda.arn
  handler          = "slack_lambda.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = module.lambda_code.zip_output_base64sha256
  publish          = false

  environment {
    variables = {
      slack_webhook_url_parameter = var.slack_webhook_url_parameter
      slack_channel               = var.slack_channel,
      slack_username              = var.slack_username,
      slack_icon                  = var.slack_icon
      slack_alarm_emoji           = var.slack_alarm_emoji
      slack_ok_emoji              = var.slack_ok_emoji
    }
  }

  depends_on = [module.lambda_code.resource_check]
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

resource "aws_lambda_permission" "allow_sns_trigger" {
  statement_id  = "AllowExecutionBySNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.slack_topic_arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = var.slack_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_lambda.arn
}
