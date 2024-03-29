## CloudWatch

resource "aws_cloudwatch_log_group" "unmatched" {
  name = "${var.env_name}_unmatched_kms_events"
}

# event rule for custom events
resource "aws_cloudwatch_event_rule" "unmatched" {
  name        = "${var.env_name}-unmatched-kmslog"
  description = "Capture Unmatched KMS Log Events"

  event_pattern = <<PATTERN
{
    "source":["gov.login.app"],
    "detail": {"environment": ["${var.env_name}"]}
}
PATTERN
}

resource "aws_cloudwatch_event_target" "unmatched_sqs" {
  rule = aws_cloudwatch_event_rule.unmatched.name
  arn  = aws_sqs_queue.unmatched.arn
}

resource "aws_cloudwatch_event_target" "unmatched_log_group" {
  rule = aws_cloudwatch_event_rule.unmatched.name
  arn  = aws_cloudwatch_log_group.unmatched.arn
}

## SQS

data "aws_iam_policy_document" "event_to_sqs_policy" {
  statement {
    sid     = "AllowEventsToSQS"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [aws_sqs_queue.unmatched.arn]
  }
}

resource "aws_sqs_queue_policy" "events_to_sqs" {
  queue_url = aws_sqs_queue.unmatched.id
  policy    = data.aws_iam_policy_document.event_to_sqs_policy.json
}

# create queue for batching unmatched events
resource "aws_sqs_queue" "unmatched" {
  name                              = "${var.env_name}-kms-unmatched-events"
  delay_seconds                     = 5
  max_message_size                  = 2048
  visibility_timeout_seconds        = 120
  message_retention_seconds         = 345600 # 4 days
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  redrive_policy                    = <<POLICY
{
    "deadLetterTargetArn": "${aws_sqs_queue.unmatched_slack_dead_letter.arn}",
    "maxReceiveCount": ${var.ct_queue_maxreceivecount}
}
POLICY

  tags = {
    environment = var.env_name
  }
}

module "unmatched_queue_alerts" {
  source = "github.com/18F/identity-terraform//sqs_alerts?ref=660048415b30fab9662b1cb32d59672b168be91a"
  #source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.unmatched.name
  max_message_size = aws_sqs_queue.unmatched.max_message_size
  alarm_actions    = var.sqs_alarm_actions
  ok_actions       = var.sqs_ok_actions
}

# create dead letter queue for batching unmatched events
resource "aws_sqs_queue" "unmatched_slack_dead_letter" {
  name                              = "${var.env_name}-kms-slack-dead-letter"
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  message_retention_seconds         = 604800 # 7 days
  tags = {
    environment = var.env_name
  }
}

# create dead letter queue for kms cloudtrail events
resource "aws_sqs_queue" "dead_letter" {
  name                              = "${var.env_name}-kms-dead-letter"
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  message_retention_seconds         = 604800 # 7 days
  tags = {
    environment = var.env_name
  }
}

## Lambda

data "aws_iam_policy_document" "slack_processor" {
  statement {
    sid    = "CreateLogGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
  statement {
    sid    = "PutLogEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.slack_processor_lambda_name}:*"
    ]
  }
  statement {
    sid    = "AllowManagingSQS"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.unmatched.arn
    ]
  }
}

data "aws_iam_policy_document" "unmatched_lambda_to_slack" {
  count = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowPublishSNS"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      for arn in var.alarm_sns_topic_arns : arn
    ]
  }
}

resource "aws_iam_role" "slack_processor" {
  name               = "${local.slack_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "slack_processor" {
  role   = aws_iam_role.slack_processor.name
  policy = data.aws_iam_policy_document.slack_processor.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "unmatched_lambda_to_slack" {
  count  = length(var.alarm_sns_topic_arns) > 0 ? 1 : 0
  role   = aws_iam_role.slack_processor.name
  policy = data.aws_iam_policy_document.unmatched_lambda_to_slack[count.index].json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "lambda_kms" {
  role   = aws_iam_role.slack_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy_attachment" "slack_processor_insights" {
  role       = aws_iam_role.slack_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

resource "aws_lambda_function" "slack_processor" {
  filename      = var.lambda_slack_batch_processor_zip
  function_name = local.slack_processor_lambda_name
  description   = "KMS Slack Batch Processor"
  role          = aws_iam_role.slack_processor.arn
  handler       = "kms_slack_batch_processor.lambda_handler"
  runtime       = "python3.9"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights_arn
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = merge(
      {
        env            = var.env_name
        log_group_name = aws_cloudwatch_log_group.unmatched.name
      },
      length(var.alarm_sns_topic_arns) > 0 ? { arn = var.alarm_sns_topic_arns[0] } : {}
    )
  }
}

module "slack-processor-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=f6bb6ede0d969ea8f62ebba3cbcedcba834aee2f"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.slack_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.slack_processor.timeout
}

resource "aws_lambda_event_source_mapping" "sqs_to_batch_processor" {
  event_source_arn                   = aws_sqs_queue.unmatched.arn
  function_name                      = aws_lambda_function.slack_processor.arn
  maximum_batching_window_in_seconds = 300
  batch_size                         = 100
}
