locals {

  dead_letter_queues = [
    aws_sqs_queue.dead_letter.name,
    aws_sqs_queue.unmatched_slack_dead_letter.name,
    aws_sqs_queue.cloudtrail_requeue_dead_letter.name,
  ]

  default_variables = {
    env            = var.env_name
    log_group_name = aws_cloudwatch_log_group.unmatched.name
  }

  alarm_variables      = length(var.alarm_sns_topic_arns) > 0 ? { arn = var.alarm_sns_topic_arns[0] } : {}
  lambda_env_variables = merge(local.default_variables, local.alarm_variables)
  lambda_insights      = "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer:LambdaInsightsExtension:${var.lambda_insights_version}"

}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy" "insights" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

data "aws_iam_policy_document" "kms" {
  # Allow root users in
  statement {
    actions = [
      "kms:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*",
    ]
  }

  # allow an EC2 instance role to use KMS
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    principals {
      type = "AWS"
      identifiers = concat(
        var.ec2_kms_arns
      )
    }
    resources = [
      "*",
    ]
  }

  # Allow CloudWatch Events and SNS Access
  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sns.amazonaws.com",
      ]
    }
  }
}

# iam policy for sqs that allows cloudwatch events to 
# deliver events to the queue
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
    #condition {
    #  test     = "StringLike"
    #  variable = "aws:SourceArn"
    #  values = [
    #    "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${var.env_name}-decryption-events-*",
    #  ]
    #}
  }
}

resource "null_resource" "kms_log_found" {
  triggers = {
    kms_log = "${var.env_name}_/srv/idp/shared/log/kms.log"
  }
}

locals {
  kms_alias                   = "alias/${var.env_name}-kms-logging"
  dynamodb_table_name         = "${var.env_name}-kms-logging"
  kinesis_stream_name         = "${var.env_name}-kms-app-events"
  kmslog_event_rule_name      = "${var.env_name}-unmatched-kmslog"
  dashboard_name              = "${var.env_name}-kms-logging"
  ct_processor_lambda_name    = "${var.env_name}-cloudtrail-kms"
  ct_requeue_lambda_name      = "${var.env_name}-kms-cloudtrail-requeue"
  cw_processor_lambda_name    = "${var.env_name}-cloudwatch-kms"
  event_processor_lambda_name = "${var.env_name}-kmslog-event-processor"
  slack_processor_lambda_name = "${var.env_name}-kms-slack-batch-processor"
}

# create cmk for kms logging solution
resource "aws_kms_key" "kms_logging" {
  description         = "KMS logging key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json
  tags = {
    Name        = "${var.env_name} KMS Logging Key"
    environment = var.env_name
  }
}

resource "aws_kms_alias" "kms_logging" {
  name          = local.kms_alias
  target_key_id = aws_kms_key.kms_logging.key_id
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
  #source = "github.com/18F/identity-terraform//sqs_alerts?ref="
  source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.unmatched.name
  max_message_size = aws_sqs_queue.unmatched.max_message_size
}

resource "aws_sqs_queue_policy" "events_to_sqs" {
  queue_url = aws_sqs_queue.unmatched.id
  policy    = data.aws_iam_policy_document.event_to_sqs_policy.json
}

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

resource "aws_cloudwatch_log_group" "unmatched" {
  name = "${var.env_name}_unmatched_kms_events"
}

resource "aws_iam_role" "slack_processor" {
  name = "${var.env_name}_kms_sqs_to_slack_processor"
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

resource "aws_iam_role_policy" "lambda_kms" {
  role   = aws_iam_role.slack_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy_attachment" "slack_processor_insights" {
  role       = aws_iam_role.slack_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

resource "aws_iam_policy" "sqs_to_lambda_policy" {
  name = "${var.env_name}_unmatched_sqs_to_lambda"
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
  name  = "${var.env_name}_unmatched_lambda_to_slack"
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
  name = "${var.env_name}_unmatched_lambda_to_cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.slack_processor_lambda_name}:*"
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

module "slack-processor-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b7933bfe952caa1df591bdbb12c5209a9184aa25"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.slack_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
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
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = local.lambda_env_variables
  }
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

# queue for cloudtrail requeueing service
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

# create dead letter queue for kms cloudtrail requeue service 
resource "aws_sqs_queue" "cloudtrail_requeue_dead_letter" {
  name                              = "${var.env_name}-kms-ct-requeue-dead-letter"
  kms_master_key_id                 = aws_kms_key.kms_logging.arn
  kms_data_key_reuse_period_seconds = 600
  message_retention_seconds         = 604800 # 7 days
  tags = {
    environment = var.env_name
  }
}

# queue for cloudtrail kms events
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
  #source = "github.com/18F/identity-terraform//sqs_alerts?ref="
  source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.kms_ct_events.name
  max_message_size = aws_sqs_queue.kms_ct_events.max_message_size
}

resource "aws_sqs_queue_policy" "default" {
  queue_url = aws_sqs_queue.kms_ct_events.id
  policy    = data.aws_iam_policy_document.sqs_kms_ct_events_policy.json
}

# event rule for custom events
resource "aws_cloudwatch_event_rule" "unmatched" {
  name        = local.kmslog_event_rule_name
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

# dynamodb table for event correlation
resource "aws_dynamodb_table" "kms_events" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UUID"
  range_key    = "Timestamp"

  attribute {
    name = "UUID"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }

  attribute {
    name = "Correlated"
    type = "S"
  }

  global_secondary_index {
    name            = "Correlated_Index"
    hash_key        = "UUID"
    range_key       = "Correlated"
    projection_type = "KEYS_ONLY"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = local.dynamodb_table_name
    environment = var.env_name
  }
}

# sns topic for metrics and events sent
# by the lambda that process the cloudtrail 
# events
resource "aws_sns_topic" "kms_logging_events" {
  name              = "${var.env_name}-kms-logging-events"
  display_name      = "KMS Events"
  kms_master_key_id = local.kms_alias
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
  #source = "github.com/18F/identity-terraform//sqs_alerts?ref="
  source = "../sqs_alerts"

  queue_name       = aws_sqs_queue.kms_cloudwatch_events.name
  max_message_size = aws_sqs_queue.kms_cloudwatch_events.max_message_size
}

resource "aws_sqs_queue_policy" "kms_cloudwatch_events" {
  queue_url = aws_sqs_queue.kms_cloudwatch_events.id
  policy    = data.aws_iam_policy_document.sqs_kms_cw_events_policy.json
}

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

# subscription for cloudwatch metrics queue to the sns topic
resource "aws_sns_topic_subscription" "kms_events_sqs_cw_target" {
  topic_arn = aws_sns_topic.kms_logging_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.kms_cloudwatch_events.arn
}

# create kinesis data stream for application kms events
resource "aws_kinesis_stream" "datastream" {
  name        = local.kinesis_stream_name
  shard_count = var.kinesis_shard_count

  retention_period = var.kinesis_retention_hours
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  shard_level_metrics = [
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
  ]

  tags = {
    environment = var.env_name
  }
}

# policy to allow kinesis access to cloudwatch
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

# policy to allow cloudwatch to put log records into kinesis
data "aws_iam_policy_document" "cloudwatch_access" {
  statement {
    sid    = "KinesisPut"
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
    ]
    resources = [
      aws_kinesis_stream.datastream.arn,
    ]
  }
}

# kinesis role 
resource "aws_iam_role" "cloudwatch_to_kinesis" {
  name               = local.kinesis_stream_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# add cloudwatch access to kinesis role
resource "aws_iam_role_policy" "cloudwatch_access" {
  name   = "cloudwatch_access"
  role   = aws_iam_role.cloudwatch_to_kinesis.name
  policy = data.aws_iam_policy_document.cloudwatch_access.json
}

# set cloudwatch destination
resource "aws_cloudwatch_log_destination" "datastream" {
  name       = local.kinesis_stream_name
  role_arn   = aws_iam_role.cloudwatch_to_kinesis.arn
  target_arn = aws_kinesis_stream.datastream.arn
}

# configure policy to allow subscription acccess
data "aws_iam_policy_document" "subscription" {
  statement {
    sid     = "PutSubscription"
    actions = ["logs:PutSubscriptionFilter"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    resources = [
      aws_cloudwatch_log_destination.datastream.arn,
    ]
  }
}

# create destination polciy
resource "aws_cloudwatch_log_destination_policy" "subscription" {
  destination_name = aws_cloudwatch_log_destination.datastream.name
  access_policy    = data.aws_iam_policy_document.subscription.json
}

# create subscription filter 
# this filter will send the kms.log events to kinesis
resource "aws_cloudwatch_log_subscription_filter" "kinesis" {
  depends_on = [null_resource.kms_log_found]

  name            = "${var.env_name}-kms-app-log"
  log_group_name  = "${var.env_name}_/srv/idp/shared/log/kms.log"
  filter_pattern  = var.cloudwatch_filter_pattern
  destination_arn = aws_kinesis_stream.datastream.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn
}

resource "aws_cloudwatch_dashboard" "kms_log" {
  dashboard_name = local.dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${aws_sqs_queue.dead_letter.name}", { "stat": "Sum", "period": 86400 } ]
                ],
                "view": "singleValue",
                "region": "us-west-2",
                "title": "Dead Letter Day",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Lambda", "IteratorAge", "FunctionName", "${local.cw_processor_lambda_name}" ]
                ],
                "region": "us-west-2",
                "title": "Cloudwatch Kinesis queue age"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${aws_sqs_queue.kms_ct_events.name}" ]
                ],
                "region": "us-west-2",
                "title": "CloudTrail SQS queue depth"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${aws_sqs_queue.kms_cloudwatch_events.name}" ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "." ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "CloudWatch events queue"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Kinesis", "PutRecord.Success", "StreamName", "${aws_kinesis_stream.datastream.name}" ],
                    [ ".", "GetRecords.Success", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "Kinesis"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 3,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", "${aws_dynamodb_table.kms_events.name}", "Operation", "PutItem", { "period": 300 } ],
                    [ "...", "GetItem" ],
                    [ "...", "Query" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DynamoDB Latency"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${aws_dynamodb_table.kms_events.name}" ],
                    [ ".", "ConsumedWriteCapacityUnits", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "DynamoDB Capacity"
            }
        }
    ]
}
EOF

}

resource "aws_cloudwatch_metric_alarm" "dead_letter" {
  for_each            = toset(local.dead_letter_queues)
  alarm_name          = each.key
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfMessagesReceived"
  namespace           = "AWS/SQS"
  dimensions = {
    QueueName = each.key
  }
  period             = "180"
  statistic          = "Sum"
  threshold          = 1
  alarm_description  = "This alarm notifies when messages are on dead letter queue"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_lambda_backlog" {
  alarm_name          = "${var.env_name}-cloudwatch-kms-backlog"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/Lambda"
  metric_name         = "IteratorAge"
  dimensions = {
    FunctionName = local.cw_processor_lambda_name
  }
  period    = "180"
  statistic = "Maximum"

  # 3600000 ms = 1 hour
  threshold          = 3600000
  alarm_description  = "Kinesis backlog for ${var.env_name}-cloudwatch-kms"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_lambda_backlog" {
  alarm_name          = "${var.env_name}-cloudtrail-kms-backlog"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  dimensions = {
    QueueName = aws_sqs_queue.kms_ct_events.name
  }
  period    = "180"
  statistic = "Maximum"

  # the previous alarm is measured in milliseconds, this is a raw number of
  # messages - it has never gone above 1, but if the Lambda breaks it will
  # get to 10000 in under an hour
  threshold          = 10000
  alarm_description  = "Kinesis backlog for ${var.env_name}-cloudtrail-kms"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}

resource "aws_iam_role" "cloudtrail_requeue" {
  name = "${var.env_name}_cloudtrail_requeue_service"
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

resource "aws_iam_role_policy" "ctrequeue_cloudwatch" {
  name   = "ctrequeue_cloudwatch"
  role   = aws_iam_role.cloudtrail_requeue.id
  policy = data.aws_iam_policy_document.ctrequeue_cloudwatch.json
}

resource "aws_iam_role_policy" "ctrequeue_kms" {
  name   = "ctrequeue_kms"
  role   = aws_iam_role.cloudtrail_requeue.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy" "ctrequeue_sqs" {
  name   = "ctprocessor_sqs"
  role   = aws_iam_role.cloudtrail_requeue.id
  policy = data.aws_iam_policy_document.ctrequeue_sqs.json
}

resource "aws_iam_role_policy_attachment" "ctrequeue_insights" {
  role       = aws_iam_role.cloudtrail_requeue.id
  policy_arn = data.aws_iam_policy.insights.arn
}

data "aws_iam_policy_document" "ctrequeue_cloudwatch" {
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.ct_requeue_lambda_name}:*",
    ]
  }
}

data "aws_iam_policy_document" "ctrequeue_sqs" {
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

# Scheduled Trigger Expressions for cloudtrail_requeue

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.ct_requeue_lambda_name}-schedule"
  description         = "Schedule for the ${local.ct_requeue_lambda_name} function"
  schedule_expression = "rate(15 minutes)"
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
}

#lambda functions
resource "aws_lambda_function" "cloudtrail_requeue" {
  filename      = var.lambda_kms_ct_requeue_zip
  function_name = local.ct_requeue_lambda_name
  description   = "KMS CT Requeue Service"
  role          = aws_iam_role.cloudtrail_requeue.arn
  handler       = "main.IdentityKMSMonitor::CloudTrailRequeue.process"
  runtime       = "ruby3.2"
  timeout       = 900 # 15 minutes

  layers = [
    local.lambda_insights
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
}

module "ct-requeue-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b7933bfe952caa1df591bdbb12c5209a9184aa25"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.ct_requeue_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
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
    local.lambda_insights
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
}

module "ct-processor-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b7933bfe952caa1df591bdbb12c5209a9184aa25"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.ct_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
}

resource "aws_lambda_event_source_mapping" "cloudtrail_processor" {
  event_source_arn = aws_sqs_queue.kms_ct_events.arn
  function_name    = aws_lambda_function.cloudtrail_processor.arn
}

data "aws_iam_policy_document" "ctprocessor_cloudwatch" {
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.ct_processor_lambda_name}:*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_kms" {
  statement {
    sid    = "KMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      aws_kms_key.kms_logging.arn,
    ]
  }
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    sid    = "DynamoDb"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
    ]

    resources = [
      aws_dynamodb_table.kms_events.arn,
    ]
  }
}

data "aws_iam_policy_document" "ctprocessor_sns" {
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
}

data "aws_iam_policy_document" "ctprocessor_sqs" {
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

data "aws_iam_policy_document" "assume-role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "cloudtrail_processor" {
  name               = "${local.ct_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

resource "aws_iam_role_policy" "ctprocessor_cloudwatch" {
  name   = "ctprocessor_cloudwatch"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.ctprocessor_cloudwatch.json
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

resource "aws_iam_role_policy" "ctprocessor_sns" {
  name   = "ctprocessor_sns"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.ctprocessor_sns.json
}

resource "aws_iam_role_policy" "ctprocessor_sqs" {
  name   = "ctprocessor_sqs"
  role   = aws_iam_role.cloudtrail_processor.id
  policy = data.aws_iam_policy_document.ctprocessor_sqs.json
}

resource "aws_iam_role_policy_attachment" "ctprocessor_insights" {
  role       = aws_iam_role.cloudtrail_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

resource "aws_lambda_function" "cloudwatch_processor" {

  filename      = var.lambda_kms_cw_processor_zip
  function_name = local.cw_processor_lambda_name
  description   = "KMS CW Log Processor"
  role          = aws_iam_role.cloudwatch_processor.arn
  handler       = "main.IdentityKMSMonitor::CloudWatchKMSHandler.process"
  runtime       = "ruby3.2"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights
  ]

  memory_size = var.cw_processor_memory_size

  ephemeral_storage {
    size = var.cw_processor_storage_size

  }

  environment {
    variables = {
      DEBUG               = var.kmslog_lambda_debug
      DRY_RUN             = var.kmslog_lambda_dry_run
      RETENTION_DAYS      = var.dynamodb_retention_days
      DDB_TABLE           = aws_dynamodb_table.kms_events.id
      SNS_EVENT_TOPIC_ARN = aws_sns_topic.kms_logging_events.arn
    }
  }

  tags = {
    environment = var.env_name
  }
}

module "cw-processor-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b7933bfe952caa1df591bdbb12c5209a9184aa25"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.cw_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
}

resource "aws_lambda_event_source_mapping" "cloudwatch_processor" {
  event_source_arn  = aws_kinesis_stream.datastream.arn
  function_name     = aws_lambda_function.cloudwatch_processor.arn
  starting_position = "LATEST"
}

resource "aws_iam_role" "cloudwatch_processor" {
  name               = "${local.cw_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

data "aws_iam_policy_document" "cwprocessor_cloudwatch" {
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.cw_processor_lambda_name}:*",
    ]
  }
}

data "aws_iam_policy_document" "cwprocessor_sns" {
  statement {
    sid    = "cwprocessorSNS"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.kms_logging_events.arn,
    ]
  }
}

data "aws_iam_policy_document" "cwprocessor_kinesis" {
  statement {
    sid    = "Kinesis"
    effect = "Allow"
    actions = [
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:DescribeStream",
    ]

    resources = [
      aws_kinesis_stream.datastream.arn,
    ]
  }
}

resource "aws_iam_role_policy" "cwprocessor_cloudwatch" {
  name   = "cwprocessor_cloudwatch"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.cwprocessor_cloudwatch.json
}

resource "aws_iam_role_policy" "cwprocessor_dynamodb" {
  name   = "cwprocessor_dynamodb"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_iam_role_policy" "cwprocessor_kms" {
  name   = "cwprocessor_kms"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy" "cwprocessor_sns" {
  name   = "cwprocessor_sns"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.cwprocessor_sns.json
}

resource "aws_iam_role_policy" "cwprocessor_kinesis" {
  name   = "cwprocessor_kinesis"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.cwprocessor_kinesis.json
}

resource "aws_iam_role_policy_attachment" "cwprocessor_insights" {
  role       = aws_iam_role.cloudwatch_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

# lambda for creating cloudwatch metrics and events
resource "aws_lambda_function" "event_processor" {
  filename      = var.lambda_kms_event_processor_zip
  function_name = local.event_processor_lambda_name
  description   = "KMS Log Event Processor"
  role          = aws_iam_role.event_processor.arn
  handler       = "main.IdentityKMSMonitor::CloudWatchEventGenerator.process"
  runtime       = "ruby3.2"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights
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
    aws_iam_role_policy.event_processor_sqs
  ]
}

resource "aws_iam_role" "event_processor" {
  name               = "${local.event_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

data "aws_iam_policy_document" "event_processor_cloudwatch" {
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
}

data "aws_iam_policy_document" "event_processor_cloudwatch_events" {
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
}

data "aws_iam_policy_document" "event_processor_cloudwatch_metrics" {
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
}

data "aws_iam_policy_document" "event_processor_sqs" {
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

resource "aws_iam_role_policy" "event_processor_cloudwatch" {
  name   = "CloudWatch"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.event_processor_cloudwatch.json
}

resource "aws_iam_role_policy" "event_processor_cloudwatch_events" {
  name   = "CloudWatchEvents"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.event_processor_cloudwatch_events.json
}

resource "aws_iam_role_policy" "event_processor_cloudwatch_metrics" {
  name   = "CloudWatchMetrics"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.event_processor_cloudwatch_metrics.json
}

resource "aws_iam_role_policy" "event_processor_kms" {
  name   = "event_processor_kms"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy" "event_processor_sqs" {
  name   = "SQS"
  role   = aws_iam_role.event_processor.id
  policy = data.aws_iam_policy_document.event_processor_sqs.json
}

resource "aws_iam_role_policy_attachment" "event_processor_insights" {
  role       = aws_iam_role.event_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}
