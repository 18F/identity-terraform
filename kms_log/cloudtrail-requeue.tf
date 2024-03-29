## SQS

# queue for CloudTrail requeueing service
resource "aws_sqs_queue" "cloudtrail_requeue" {
  name                              = "${var.env_name}-kms-ct-requeue"
  max_message_size                  = var.ct_queue_max_message_size
  visibility_timeout_seconds        = var.ct_queue_visibility_timeout_seconds
  message_retention_seconds         = var.ct_queue_message_retention_seconds
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600 # number of seconds the kms key is cached
  redrive_policy                    = <<POLICY
{
    "deadLetterTargetArn": "${aws_sqs_queue.cloudtrail_requeue_dead_letter.arn}",
    "maxReceiveCount": ${var.ct_queue_maxreceivecount}
}
POLICY

  tags = {
    environment = var.env_name
  }
}

module "reqeue_queue_alerts" {
  source = "github.com/18F/identity-terraform//sqs_alerts?ref=660048415b30fab9662b1cb32d59672b168be91a"
  #source = "../sqs_alerts"

  queue_name                      = aws_sqs_queue.cloudtrail_requeue.name
  max_message_size                = aws_sqs_queue.cloudtrail_requeue.max_message_size
  age_of_oldest_message_threshold = 7200 # 2 hours
  alarm_actions                   = var.sqs_alarm_actions
  ok_actions                      = var.sqs_ok_actions
}

# dead letter queue for KMS CloudTrail requeue service
resource "aws_sqs_queue" "cloudtrail_requeue_dead_letter" {
  name                              = "${var.env_name}-kms-ct-requeue-dead-letter"
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  message_retention_seconds         = 604800 # 7 days
  tags = {
    environment = var.env_name
  }
}

## Lambda

data "aws_iam_policy_document" "ctrequeue" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.cloudtrail_requeue.arn,
      "${aws_cloudwatch_log_group.cloudtrail_requeue.arn}:*"
    ]
  }
  statement {
    sid    = "SQSPrimary"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.kms_ct_events.arn,
    ]
  }
  statement {
    sid    = "SQSRequeue"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.cloudtrail_requeue.arn,
    ]
  }
}

resource "aws_iam_role" "cloudtrail_requeue" {
  name               = "${local.ct_requeue_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ctrequeue" {
  name   = "ctrequeue"
  role   = aws_iam_role.cloudtrail_requeue.id
  policy = data.aws_iam_policy_document.ctrequeue.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ctrequeue_kms" {
  name   = "ctrequeue_kms"
  role   = aws_iam_role.cloudtrail_requeue.id
  policy = data.aws_iam_policy_document.lambda_kms.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ctrequeue_insights" {
  role       = aws_iam_role.cloudtrail_requeue.id
  policy_arn = data.aws_iam_policy.insights.arn

  lifecycle {
    create_before_destroy = true
  }
}

# manage log group in Terraform
resource "aws_cloudwatch_log_group" "cloudtrail_requeue" {
  name              = "/aws/lambda/${local.ct_requeue_lambda_name}"
  retention_in_days = var.cloudwatch_retention_days
}

resource "aws_lambda_function" "cloudtrail_requeue" {
  filename      = var.lambda_kms_ct_requeue_zip
  function_name = local.ct_requeue_lambda_name
  description   = "KMS CT Requeue Service"
  role          = aws_iam_role.cloudtrail_requeue.arn
  handler       = "main.IdentityKMSMonitor::CloudTrailRequeue.process"
  runtime       = "ruby3.2"
  timeout       = 900 # 15 minutes

  layers = [
    local.lambda_insights_arn
  ]

  environment {
    variables = {
      DEBUG          = var.kmslog_lambda_debug
      DRY_RUN        = var.kmslog_lambda_dry_run
      CT_QUEUE_URL   = aws_sqs_queue.kms_ct_events.id
      CT_REQUEUE_URL = aws_sqs_queue.cloudtrail_requeue.id
    }
  }

  tags = {
    environment = var.env_name
  }

  depends_on = [aws_cloudwatch_log_group.cloudtrail_requeue]
}

module "ct-requeue-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=f6bb6ede0d969ea8f62ebba3cbcedcba834aee2f"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.ct_requeue_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.cloudtrail_requeue.timeout
}

## CloudWatch

# Scheduled Trigger Expressions for cloudtrail_requeue
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.ct_requeue_lambda_name}-schedule"
  description         = "Schedule for the ${local.ct_requeue_lambda_name} function"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "cloudtrail_requeue_trigger" {
  count = var.ct_requeue_concurrency
  rule  = aws_cloudwatch_event_rule.schedule.name
  arn   = aws_lambda_function.cloudtrail_requeue.arn
}

resource "aws_lambda_permission" "event_bridge_to_cloudtrail_requeue" {
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudtrail_requeue.function_name
  principal     = "events.amazonaws.com"

  depends_on = [
    aws_lambda_function.cloudtrail_requeue
  ]

  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.cloudtrail_requeue.id
    ]
  }
}
