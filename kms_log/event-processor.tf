## SQS

# policy for queue that receives events for cloudwatch metrics
data "aws_iam_policy_document" "sqs_kms_cw_events_policy" {
  statement {
    sid     = "Allow SQS"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
      ]
    }
    resources = [aws_sqs_queue.kms_cloudwatch_events.arn]
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        aws_sns_topic.kms_logging_events.arn,
      ]
    }
  }
}

# queue to receive events from the logging events sns topic
# for delivery of metrics to cloudwatch
resource "aws_sqs_queue" "kms_cloudwatch_events" {
  name                              = "${var.env_name}-kms-cw-events"
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

module "kms_cloudwatch_events_queue_alerts" {
  source = "github.com/18F/identity-terraform//sqs_alerts?ref=660048415b30fab9662b1cb32d59672b168be91a"
  #source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.kms_cloudwatch_events.name
  max_message_size = aws_sqs_queue.kms_cloudwatch_events.max_message_size
  alarm_actions    = var.sqs_alarm_actions
  ok_actions       = var.sqs_ok_actions
}

resource "aws_sqs_queue_policy" "kms_cloudwatch_events" {
  queue_url = aws_sqs_queue.kms_cloudwatch_events.id
  policy    = data.aws_iam_policy_document.sqs_kms_cw_events_policy.json
}

## Lambda

data "aws_iam_policy_document" "event_processor" {
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.event_processor_lambda_name}:*",
    ]
  }
  statement {
    sid    = "CloudWatchEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "SQS"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.kms_cloudwatch_events.arn,
    ]
  }
}

resource "aws_iam_role" "event_processor" {
  name               = "${local.event_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "event_processor" {
  name   = "event_processor"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.event_processor.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "event_processor_kms" {
  name   = "event_processor_kms"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy_attachment" "event_processor_insights" {
  role       = aws_iam_role.event_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

resource "aws_lambda_function" "event_processor" {
  filename      = var.lambda_kms_event_processor_zip
  function_name = local.event_processor_lambda_name
  description   = "KMS Log Event Processor"
  role          = aws_iam_role.event_processor.arn
  handler       = "main.IdentityKMSMonitor::CloudWatchEventGenerator.process"
  runtime       = "ruby3.2"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights_arn
  ]

  environment {
    variables = {
      DEBUG    = var.kmslog_lambda_debug
      DRY_RUN  = var.kmslog_lambda_dry_run
      ENV_NAME = var.env_name
    }
  }

  tags = {
    environment = var.env_name
  }
}

resource "aws_lambda_event_source_mapping" "event_processor" {
  event_source_arn = aws_sqs_queue.kms_cloudwatch_events.arn
  function_name    = aws_lambda_function.event_processor.arn
  depends_on = [
    aws_iam_role.event_processor,
    aws_iam_role_policy.event_processor_kms,
    aws_iam_role_policy.event_processor
  ]
}
