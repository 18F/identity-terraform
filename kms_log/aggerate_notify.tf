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

resource "aws_iam_role_policy_attachment" "sqs_to_slack" {
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.sqs_to_slack_policy.arn
}

resource "aws_iam_policy" "sqs_to_slack_policy" {
  name = "kms_sqs_to_slack"
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
      {
        Sid    = "AllowPublishSNS"
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = [
          var.alarm_sns_topic_arns[0]
        ]
      },
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
  handler       = "slack_batch_processor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 120 # seconds

  tags = {
    environment = var.env_name
  }

  dynamic "environment" {
    for_each = var.alarm_sns_topic_arns
    content {
      variables = {
        arn           = environment.value
        env           = var.env_name
        log_group_arn = aws_cloudwatch_log_group.unmatched.arn
      }
    }
  }
}
