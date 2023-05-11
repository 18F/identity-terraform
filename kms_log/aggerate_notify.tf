locals {

  default_variables = {
    env            = var.env_name
    log_group_name = aws_cloudwatch_log_group.unmatched.name
  }

  alarm_variables = length(var.alarm_sns_topic_arns) > 0 ? { arn = var.alarm_sns_topic_arns[0] } : {}

  lambda_env_variables = merge(local.default_variables, local.alarm_variables)

}


resource "aws_sqs_queue" "unmatched" {
  name                              = "${var.env_name}-kms-unmatched-events"
  delay_seconds                     = 5
  max_message_size                  = 2048
  visibility_timeout_seconds        = 120
  message_retention_seconds         = 345600 # 4 days
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "unmatched" {
  name = "${var.env_name}_unmatched_kms_events"
}

resource "aws_iam_role" "slack_processor" {
  name = "kms_sqs_to_slack_processor"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_to_lambda" {
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.sqs_to_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_to_slack" {
  count      = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.lambda_to_slack_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "lambda_to_cloudwatch" {
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.lambda_to_cloudwatch_policy.arn
}

resource "aws_iam_policy" "sqs_to_lambda_policy" {
  name = "sqs_to_lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowManagingSQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [
          aws_sqs_queue.unmatched.arn
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_to_slack_policy" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0
  name  = "lambda_to_slack"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublishSNS"
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = [for arn in var.alarm_sns_topic_arns : arn]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_to_cloudwatch_policy" {
  name = "lambda_to_cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.unmatched.arn
        ]
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs_to_batch_processor" {
  event_source_arn                   = aws_sqs_queue.unmatched.arn
  function_name                      = aws_lambda_function.slack_processor.arn
  maximum_batching_window_in_seconds = 300
  batch_size                         = 100
}

resource "aws_lambda_function" "slack_processor" {
  filename      = var.lambda_slack_batch_processor_zip
  function_name = local.slack_processor_lambda_name
  description   = "KMS Slack Batch Processor"
  role          = aws_iam_role.slack_processor.arn
  handler       = "kms_slack_batch_processor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 120 # seconds

  tags = {
    environment = var.env_name
  }

  environment {
    variables = local.lambda_env_variables
  }
}
