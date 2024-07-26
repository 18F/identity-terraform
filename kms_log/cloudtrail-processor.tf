## SQS

# IAM policy for SQS that allows CloudWatch events to deliver events to the queue
data "aws_iam_policy_document" "sqs_kms_ct_events_policy" {
  statement {
    sid     = "Allow SNS Messages"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    resources = [aws_sqs_queue.kms_ct_events.arn]
  }
}

resource "aws_sqs_queue_policy" "default" {
  queue_url = aws_sqs_queue.kms_ct_events.id
  policy    = data.aws_iam_policy_document.sqs_kms_ct_events_policy.json
}

# queue for CloudTrail KMS events
resource "aws_sqs_queue" "kms_ct_events" {
  name                              = "${var.env_name}-kms-ct-events"
  delay_seconds                     = var.ct_queue_delay_seconds
  max_message_size                  = var.ct_queue_max_message_size
  visibility_timeout_seconds        = var.ct_queue_visibility_timeout_seconds
  message_retention_seconds         = var.ct_queue_message_retention_seconds
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600 # number of seconds the kms key is cached
  redrive_policy                    = <<POLICY
{
    "deadLetterTargetArn": "${aws_sqs_queue.dead_letter.arn}",
    "maxReceiveCount": ${var.ct_queue_maxreceivecount}
}
POLICY

  tags = {
    environment = var.env_name
  }
}

module "kms_ct_queue_alerts" {
  source = "github.com/18F/identity-terraform//sqs_alerts?ref=660048415b30fab9662b1cb32d59672b168be91a"
  #source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.kms_ct_events.name
  max_message_size = aws_sqs_queue.kms_ct_events.max_message_size
  alarm_actions    = var.sqs_alarm_actions
  ok_actions       = var.sqs_ok_actions
}

## Lambda

data "aws_iam_policy_document" "ctprocessor" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.cloudtrail_processor.arn,
      "${aws_cloudwatch_log_group.cloudtrail_processor.arn}:*"
    ]
  }
  statement {
    sid    = "ctprocessorSNS"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.kms_logging_events.arn,
    ]
  }
  statement {
    sid    = "SQSPrimary"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.kms_ct_events.arn,
    ]
  }
  statement {
    sid    = "SQSRequeue"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.cloudtrail_requeue.arn,
    ]
  }
}

resource "aws_iam_role" "cloudtrail_processor" {
  name               = "${local.ct_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ctprocessor" {
  name   = "ctprocessor"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.ctprocessor.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ctprocessor_dynamodb" {
  name   = "ctprocessor_dynamodb"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_iam_role_policy" "ctprocessor_kms" {
  name   = "ctprocessor_kms"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy_attachment" "ctprocessor_insights" {
  role       = aws_iam_role.cloudtrail_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

# manage log group in Terraform
resource "aws_cloudwatch_log_group" "cloudtrail_processor" {
  name              = "/aws/lambda/${local.ct_processor_lambda_name}"
  retention_in_days = var.cloudwatch_retention_days
}

resource "aws_lambda_function" "cloudtrail_processor" {
  filename      = var.lambda_kms_ct_processor_zip
  function_name = local.ct_processor_lambda_name
  description   = "KMS CT Log Processor"
  role          = aws_iam_role.cloudtrail_processor.arn
  handler       = "main.IdentityKMSMonitor::CloudTrailToDynamoHandler.process"
  runtime       = "ruby3.2"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights_arn
  ]

  environment {
    variables = {
      DEBUG               = var.kmslog_lambda_debug
      DRY_RUN             = var.kmslog_lambda_dry_run
      CT_QUEUE_URL        = aws_sqs_queue.kms_ct_events.id
      CT_REQUEUE_URL      = aws_sqs_queue.cloudtrail_requeue.id
      RETENTION_DAYS      = var.dynamodb_retention_days
      DDB_TABLE           = aws_dynamodb_table.kms_events.id
      SNS_EVENT_TOPIC_ARN = aws_sns_topic.kms_logging_events.arn
    }
  }

  tags = {
    environment = var.env_name
  }

  depends_on = [aws_cloudwatch_log_group.cloudtrail_processor]
}

module "ct-processor-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=e0e39adea82243d66c3c1218c7a4316b81f64560"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.ct_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.cloudtrail_processor.timeout
  treat_missing_data   = "ignore"
}

resource "aws_lambda_event_source_mapping" "cloudtrail_processor" {
  event_source_arn = aws_sqs_queue.kms_ct_events.arn
  function_name    = aws_lambda_function.cloudtrail_processor.arn
}
