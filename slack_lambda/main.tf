# -- Data Sources --

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.slack_webhook_url_parameter}"
    ]
  }
}

module "slack_lambda" {
  source = "github.com/18F/identity-terraform//lambda_function?ref=026f69d0a5e2b8af458888a5f21a72d557bbe1fe"
  #source = "../lambda_function"

  // region               = var.region
  function_name        = var.lambda_name
  description          = var.lambda_description
  source_code_filename = "slack_lambda.py"
  source_dir           = "${path.module}/src/"
  runtime              = "python3.12"
  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory

  environment_variables = {
    slack_webhook_url_parameter = var.slack_webhook_url_parameter
    slack_channel               = var.slack_channel,
    slack_username              = var.slack_username,
    slack_icon                  = var.slack_icon
    slack_alarm_emoji           = var.slack_alarm_emoji
    slack_warn_emoji            = var.slack_warn_emoji
    slack_notice_emoji          = var.slack_notice_emoji
    slack_ok_emoji              = var.slack_ok_emoji
  }

  cloudwatch_retention_days = 365
  insights_enabled          = false
  alarm_actions = [
  ]

  role_name_prefix = var.lambda_name

  lambda_iam_policy_document = data.aws_iam_policy_document.lambda_policy.json
}

moved {
  from = aws_lambda_function.slack_lambda
  to   = module.slack_lambda.aws_lambda_function.lambda
}

moved {
  from = aws_cloudwatch_log_group.slack_lambda
  to   = module.slack_lambda.aws_cloudwatch_log_group.lambda
}

moved {
  from = aws_iam_role.slack_lambda
  to   = module.slack_lambda.aws_iam_role.lambda
}

moved {
  from = aws_iam_role_policy.slack_lambda
  to   = module.slack_lambda.aws_iam_role_policy.lambda
}

resource "aws_lambda_permission" "allow_sns_trigger" {
  statement_id  = "AllowExecutionBySNS"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_lambda.lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.slack_topic_arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = var.slack_topic_arn
  protocol  = "lambda"
  endpoint  = module.slack_lambda.lambda_arn
}
