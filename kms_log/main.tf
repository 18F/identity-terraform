data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "ct_log_bucket"
{
    bucket = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
}

data "aws_kms_key" "application"
{
    key_id = "alias/${var.env_name}-login-dot-gov-keymaker"
}


data "aws_s3_bucket" "lambda"
{
    bucket = "login-gov.lambda-functions.${data.aws_caller_identity.current.account_id}-${var.region}"
}

locals {
    kms_alias = "alias/${var.env_name}-kms-logging"
    dynamodb_table_name = "${var.env_name}-kms-logging"
    kinesis_stream_name = "${var.env_name}-kms-app-events"
    decryption_event_rule_name = "${var.env_name}-decryption-events"
    kmslog_event_rule_name = "${var.env_name}-unmatched-kmslog"
    dashboard_name = "${var.env_name}-kms-logging"
    ct_processor_lambda_name = "${var.env_name}-kmslog-ct-processor"
    cw_processor_lambda_name = "${var.env_name}-kmslog-cw-processor"
    event_processor_lambda_name = "${var.env_name}-kmslog-event-processor"
}

# create cmk for kms logging solution
resource "aws_kms_key" "kms_logging" {
    description = "KMS logging key"
    enable_key_rotation = true
    policy = "${data.aws_iam_policy_document.kms.json}"
    tags {
       Name = "${var.env_name} KMS Logging Key"
       environment = "${var.env_name}" 
    }
}

# IAM policy for KMS access by CW Events and SNS
data "aws_iam_policy_document" "kms"
{
    statement {
        sid = "Enable IAM User Permissions"
        effect = "Allow"
        actions = [
            "kms:*"
        ]
        resources = [
            "*"
        ]
        principals {
            type = "AWS"
            identifiers = [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            ]
        }
    }

    statement {
        sid = "Allow CloudWatch Events and SNS Access"
        effect = "Allow"
        actions = [
            "kms:GenerateDataKey",
            "kms:Decrypt"
        ]
        resources = [
            "*"
        ]
        principals {
            type = "Service"
            identifiers = [
                "events.amazonaws.com",
                "sns.amazonaws.com"
            ]
        }
    }
}

resource "aws_kms_alias" "kms_logging" {
    name = "${local.kms_alias}"
    target_key_id = "${aws_kms_key.kms_logging.key_id}"
}

# create dead letter queue for kms cloudtrail events
resource "aws_sqs_queue" "dead_letter" {
    name = "${var.env_name}-kms-dead-letter"
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600
    message_retention_seconds = 604800 # 7 days
    tags = {
        environment = "${var.env_name}"
    }
}

# queue for cloudtrail kms events
resource "aws_sqs_queue" "kms_ct_events" {
    name = "${var.env_name}-kms-ct-events"
    delay_seconds = "${var.ct_queue_delay_seconds}"
    max_message_size =  "${var.ct_queue_max_message_size}"
    visibility_timeout_seconds = "${var.ct_queue_visibility_timeout_seconds}"
    message_retention_seconds = "${var.ct_queue_message_retention_seconds}"
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600 # number of seconds the kms key is cached
    redrive_policy = <<POLICY
{
    "deadLetterTargetArn": "${aws_sqs_queue.dead_letter.arn}",
    "maxReceiveCount": ${var.ct_queue_maxreceivecount}
}
POLICY
tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_sqs_queue_policy" "default" {
    queue_url = "${aws_sqs_queue.kms_ct_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_ct_events_policy.json}"
}

# iam policy for sqs that allows cloudwatch events to 
# deliver events to the queue
data "aws_iam_policy_document" "sqs_kms_ct_events_policy" {
    statement {
        sid = "Allow CloudWatch Events"
        effect = "Allow"
        actions = ["sqs:SendMessage"]
        principals {
            type = "Service"
            identifiers = ["events.amazonaws.com"]
        }
        resources = ["${aws_sqs_queue.kms_ct_events.arn}"]
        condition {
            test = "StringLike"
            variable = "aws:SourceArn"
            values = [
                "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/${local.kmslog_event_rule_name}"
            ]

        }
    }
}

# cloudwatch event rule to capture cloudtrail kms decryption events
# this filter will only capture events where the
# encryption context is set and has the values of
# password-digest or pii-encryption
# this filter also is only capturing events for a single 
# kms key
resource "aws_cloudwatch_event_rule" "decrypt" {
    count = "${var.kmslogging_service_enabled}"
    name = "${local.decryption_event_rule_name}"
    description = "Capture decryption events"

    event_pattern = <<PATTERN
{
    "source": [
        "aws.kms"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
            "kms.amazonaws.com"
        ],
        "requestParameters": {
            "encryptionContext": {
                "context": [
                    "password-digest",
                    "pii-encryption"
                ]
            }
        },
        "resources": {
            "ARN": [
                "${data.aws_kms_key.application.arn}"
            ]
        },
        "eventName": [
            "Decrypt"
        ]
    }
}
PATTERN
}

# sets the receiver of the cloudwatch events
# to the sqs queue
resource "aws_cloudwatch_event_target" "sqs" {
    count = "${var.kmslogging_service_enabled}"
    rule = "${aws_cloudwatch_event_rule.decrypt.name}"
    target_id = "${var.env_name}-sqs"
    arn = "${aws_sqs_queue.kms_ct_events.arn}"
}

# event rule for custom events
resource "aws_cloudwatch_event_rule" "unmatched" {
    count = "${var.kmslogging_service_enabled}"
    name = "${local.kmslog_event_rule_name}"
    description = "Capture Unmatched KMS Log Events"

    event_pattern = <<PATTERN
{
    "source":"gov.login.app"
}
PATTERN
}

resource "aws_cloudwatch_event_target" "unmatched" {
    count = "${var.kmslogging_service_enabled}"
    rule = "${aws_cloudwatch_event_rule.unmatched.name}"
    target_id = "${var.env_name}-slack"
    arn = "${var.sns_topic_dead_letter_arn}"
}

# dynamodb table for event correlation
resource "aws_dynamodb_table" "kms_events" {
    name = "${local.dynamodb_table_name}"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "UUID"
    range_key = "Timestamp"

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
        name = "Correlated_Index"
        hash_key = "UUID"
        range_key = "Correlated"
        projection_type = "KEYS_ONLY"
    }

    ttl {
        attribute_name = "TimeToExist"
        enabled = true
    }

    point_in_time_recovery {
        enabled = true
    }

    server_side_encryption {
        enabled = true
    }

  tags = {
    Name = "${local.dynamodb_table_name}"
    environment = "${var.env_name}"
  }
}

# sns topic for metrics and events sent
# by the lambda that process the cloudtrail 
# events
resource "aws_sns_topic" "kms_logging_events" {
    name = "${var.env_name}-kms-logging-events"
    display_name = "KMS Events"
    kms_master_key_id = "${local.kms_alias}"
}

# queue to receive events from the logging events
# sns topic for delivery of metrics to cloudwatch
resource "aws_sqs_queue" "kms_cloudwatch_events" {
    name = "${var.env_name}-kms-cw-events"
    delay_seconds = 5
    max_message_size = 2048
    visibility_timeout_seconds = 60
    message_retention_seconds = 345600 # 4 days
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600
    tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_sqs_queue_policy" "kms_cloudwatch_events" {
    queue_url = "${aws_sqs_queue.kms_cloudwatch_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_cw_events_policy.json}"
}

# policy for queue that receives events for cloudwatch metrics
data "aws_iam_policy_document" "sqs_kms_cw_events_policy" {
    statement {
        sid = "Allow SQS"
        effect = "Allow"
        actions = ["sqs:SendMessage"]
        principals {
            type        = "AWS"
            identifiers = ["${data.aws_caller_identity.current.account_id}"]
        }
        resources = ["${aws_sqs_queue.kms_cloudwatch_events.arn}"]
        condition {
            test = "StringLike"
            variable = "aws:SourceArn"
            values = [
                "${aws_sns_topic.kms_logging_events.arn}"
            ]

        }
    }
}

# subscription for cloudwatch metrics queue to the sns topic
resource "aws_sns_topic_subscription" "kms_events_sqs_cw_target" {
    topic_arn = "${aws_sns_topic.kms_logging_events.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.kms_cloudwatch_events.arn}"
}

# queue to deliver metrics from cloudtrail lambda to
# elasticsearch
resource "aws_sqs_queue" "kms_elasticsearch_events" {
    name = "${var.env_name}-kms-es-events"
    delay_seconds = 5
    max_message_size = 2048
    visibility_timeout_seconds = 60
    message_retention_seconds = 345600 # 4 days
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600
    tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_sqs_queue_policy" "es_events"{
    queue_url = "${aws_sqs_queue.kms_elasticsearch_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_es_events_policy.json}"
}

# elasticsearch queue policy
data "aws_iam_policy_document" "sqs_kms_es_events_policy" {
    statement {
        sid = "Allow SNS"
        effect = "Allow"
        actions = ["sqs:SendMessage"]
        principals {
            type        = "AWS"
            identifiers = ["${data.aws_caller_identity.current.account_id}"]
        }
        resources = ["${aws_sqs_queue.kms_elasticsearch_events.arn}"]
        condition {
            test = "StringLike"
            variable = "aws:SourceArn"
            values = [
                "${aws_sns_topic.kms_logging_events.arn}"
            ]
        }
    }
}

# elasticsearch queue subscription to sns topic for metrics
resource "aws_sns_topic_subscription" "kms_events_sqs_es_target" {
    topic_arn = "${aws_sns_topic.kms_logging_events.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.kms_elasticsearch_events.arn}"
}

# create kinesis data stream for application kms events
resource "aws_kinesis_stream" "datastream" {
    name = "${var.env_name}-kms-app-events"
    shard_count = "${var.kinesis_shard_count}"
    retention_period = "${var.kinesis_retention_hours}"
    encryption_type = "KMS",
    kms_key_id="alias/aws/kinesis"

    shard_level_metrics = [
        "ReadProvisionedThroughputExceeded",
        "WriteProvisionedThroughputExceeded"
    ]
    
    tags {
        environment = "${var.env_name}"
    }
}

# policy to allow kinesis access to cloudwatch
data "aws_iam_policy_document" "assume_role" {
    statement {
        sid = "AssumeRole"
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
     sid = "KinesisPut" 
     effect = "Allow"
     actions = [
       "kinesis:PutRecord"
     ]
     resources = [
       "${aws_kinesis_stream.datastream.arn}"
     ]
   }
}

# kinesis role 
resource "aws_iam_role" "cloudwatch_to_kinesis" {
 name = "${local.kinesis_stream_name}"
 path = "/"
 assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

# add cloudwatch access to kinesis role
resource "aws_iam_role_policy" "cloudwatch_access" {
    name = "cloudwatch"
    role = "${aws_iam_role.cloudwatch_to_kinesis.name}"
    policy = "${data.aws_iam_policy_document.cloudwatch_access.json}"
}

# set cloudwatch destination
resource "aws_cloudwatch_log_destination" "datastream" {
    name = "${local.kinesis_stream_name}"
    role_arn = "${aws_iam_role.cloudwatch_to_kinesis.arn}"
    target_arn = "${aws_kinesis_stream.datastream.arn}"
}

# configure policy to allow subscription acccess
data "aws_iam_policy_document" "subscription" {
    statement {
        sid = "PutSubscription"
        actions = ["logs:PutSubscriptionFilter"]

        principals {
            type        = "AWS"
            identifiers = ["${data.aws_caller_identity.current.account_id}"]
        }

        resources = [
            "${aws_cloudwatch_log_destination.datastream.arn}"
        ]
    }
}

# create destination polciy
resource "aws_cloudwatch_log_destination_policy" "subscription" {
    destination_name = "${aws_cloudwatch_log_destination.datastream.name}"
    access_policy = "${data.aws_iam_policy_document.subscription.json}"
}

# create subscription filter 
# this filter will send the kms.log events to kinesis
resource "aws_cloudwatch_log_subscription_filter" "kinesis" {
    count = "${var.kmslogging_service_enabled}"
    name = "${var.env_name}-kms-app-log"
    log_group_name = "${var.env_name}_/srv/idp/shared/log/kms.log"
    filter_pattern = "${var.cloudwatch_filter_pattern}"
    destination_arn = "${aws_kinesis_stream.datastream.arn}"
    role_arn = "${aws_iam_role.cloudwatch_to_kinesis.arn}"
}

resource "aws_cloudwatch_dashboard" "kms_log" {
    dashboard_name = "${local.dashboard_name}"
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
                    [ "AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${aws_sqs_queue.kms_cloudwatch_events.name}" ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "Cloudtrail Queue"
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
                    [ "...", "GetItem" ]
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
        },
        {
            "type": "metric",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/Kinesis", "GetRecords.IteratorAgeMilliseconds", "StreamName", "${aws_kinesis_stream.datastream.name}", { "stat": "Average", "period": 86400 } ]
                ],
                "view": "singleValue",
                "region": "us-west-2",
                "title": "Kinesis Iterator Day",
                "period": 300
            }
        }
    ]
}
EOF
}

resource "aws_cloudwatch_metric_alarm" "dead_letter" {
    alarm_name = "${var.env_name}-kms_log_dead_letter"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "NumberOfMessagesReceived"
    namespace = "AWS/SQS"
    period = "180"
    statistic = "Sum"
    threshold = 1
    alarm_description = "This alarm notifies when messages are on dead letter queue"
    treat_missing_data = "ignore"
    alarm_actions = [
        "${var.sns_topic_dead_letter_arn}"
    ]
}

#lambda functions
resource "aws_lambda_function" "cloudtrail_processor" {
    count = "${var.kmslogging_service_enabled}"
    s3_bucket = "${data.aws_s3_bucket.lambda.id}"
    s3_key = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

    lifecycle {
        ignore_changes = ["s3_key", "last_modified"]
    }

    function_name = "${local.ct_processor_lambda_name}"
    description = "18F/identity-lambda-functions: KMS CT Log Processor"
    role = "${aws_iam_role.cloudtrail_processor.arn}"
    handler = "main.Functions::IdentityKMSMonitor::CloudTrailToDynamoHandler.process"
    runtime = "ruby2.5"
    timeout = 30 # seconds

    environment {
        variables = {
            DEBUG = "${var.kmslog_lambda_debug ? "1" : ""}"
            LOG_LEVEL = "0"
            CT_SQS_QUEUE = "${aws_sqs_queue.kms_ct_events.id}"
            DDB_RETENTION_DAYS = "${var.dynamodb_retention_days}"
            DDB_TABLE = "${aws_dynamodb_table.kms_events.id}"
            SNS_EVENT_TOPIC_ARN = "${aws_sns_topic.kms_logging_events.arn}"
        }
    }

    tags {
        source_repo = "https://github.com/18F/identity-lambda-functions"
        environment = "${var.env_name}"
    }
}

resource "aws_lambda_event_source_mapping" "cloudtrail_processor" {
    count = "${var.kmslogging_service_enabled}"
    event_source_arn = "${aws_sqs_queue.kms_ct_events.arn}"
    function_name = "${aws_lambda_function.cloudtrail_processor.arn}"
}


data "aws_iam_policy_document" "ctprocessor_cloudwatch" {
    statement {
        sid = "CreateLogGroup"
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        ]
    }
    statement {
        sid = "PutLogEvents"
        effect = "Allow"
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.ct_processor_lambda_name}:*"
        ]
    }
}

data "aws_iam_policy_document" "lambda_kms" {
    statement {
        sid = "KMS"
        effect = "Allow"
        actions = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
        ]

        resources = [
            "${aws_kms_key.kms_logging.arn}"
        ]
    }
}

data "aws_iam_policy_document" "lambda_dynamodb" {
    statement {
        sid = "DynamoDb"
        effect = "Allow"
        actions = [
            "dynamodb:PutItem",
            "dynamodb:GetItem"
        ]

        resources = [
            "${aws_dynamodb_table.kms_events.arn}"
        ]
    }
}

data "aws_iam_policy_document" "ctprocessor_sns" {
    statement {
        sid = "SNS"
        effect = "Allow"
        actions = [
            "sns:Publish"
        ]

        resources = [
            "${aws_sns_topic.kms_logging_events.arn}"
        ]
    }
}

data "aws_iam_policy_document" "ctprocessor_sqs" {
    statement {
        sid = "SQS"
        effect = "Allow"
        actions = [
            "sqs:DeleteMessage",
            "sqs:ChangeMessageVisibility",
            "sqs:ReceiveMessage",
            "sqs:SendMessage",
            "sqs:GetQueueAttributes"
        ]

        resources = [
            "${aws_sqs_queue.kms_ct_events.arn}"
        ]
    }
}

data "aws_iam_policy_document" "assume-role" {
    statement {
        actions = [
            "sts:AssumeRole"
        ]
        principals {
            type = "Service"
            identifiers = [
                "lambda.amazonaws.com"
            ]
        }
    }
}

resource "aws_iam_role" "cloudtrail_processor" {
    name = "${local.ct_processor_lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

resource "aws_iam_role_policy" "ctprocessor_cloudwatch" {
    name = "CloudWatch"
    role = "${aws_iam_role.cloudtrail_processor.id}"
    policy = "${data.aws_iam_policy_document.ctprocessor_cloudwatch.json}"
}

resource "aws_iam_role_policy" "ctprocessor_dynamodb" {
    name = "DynamoDb"
    role = "${aws_iam_role.cloudtrail_processor.id}"
    policy = "${data.aws_iam_policy_document.lambda_dynamodb.json}"
}

resource "aws_iam_role_policy" "ctprocessor_kms" {
    name = "DynamoDb"
    role = "${aws_iam_role.cloudtrail_processor.id}"
    policy = "${data.aws_iam_policy_document.lambda_kms.json}"
}

resource "aws_iam_role_policy" "ctprocessor_sns" {
    name = "SNS"
    role = "${aws_iam_role.cloudtrail_processor.id}"
    policy = "${data.aws_iam_policy_document.ctprocessor_sns.json}"
}

resource "aws_iam_role_policy" "ctprocessor_sqs" {
    name = "SQS"
    role = "${aws_iam_role.cloudtrail_processor.id}"
    policy = "${data.aws_iam_policy_document.ctprocessor_sqs.json}"
}

resource "aws_lambda_function" "cloudwatch_processor" {
    count = "${var.kmslogging_service_enabled}"
    s3_bucket = "${data.aws_s3_bucket.lambda.id}"
    s3_key = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

    lifecycle {
        ignore_changes = ["s3_key", "last_modified"]
    }

    function_name = "${local.cw_processor_lambda_name}"
    description = "18F/identity-lambda-functions: KMS CW Log Processor"
    role = "${aws_iam_role.cloudwatch_processor.arn}"
    handler = "main.Functions::CloudWatchKMSHandler.process"
    runtime = "ruby2.5"
    timeout = 30 # seconds

    environment {
        variables = {
            DEBUG = "${var.kmslog_lambda_debug ? "1" : ""}"
            LOG_LEVEL = "0"
            DDB_RETENTION_DAYS = "${var.dynamodb_retention_days}"
            DDB_TABLE = "${aws_dynamodb_table.kms_events.id}"
            SNS_EVENT_TOPIC_ARN = "${aws_sns_topic.kms_logging_events.arn}"
        }
    }

    tags {
        source_repo = "https://github.com/18F/identity-lambda-functions"
        environment = "${var.env_name}"
    }
}

resource "aws_lambda_event_source_mapping" "cloudwatch_processor" {
    count = "${var.kmslogging_service_enabled}"
    event_source_arn = "${aws_kinesis_stream.datastream.arn}"
    function_name = "${aws_lambda_function.cloudwatch_processor.arn}"
    starting_position = "LATEST"
}

resource "aws_iam_role" "cloudwatch_processor" {
    name = "${local.cw_processor_lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

data "aws_iam_policy_document" "cwprocessor_cloudwatch" {
    statement {
        sid = "CreateLogGroup"
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        ]
    }
    statement {
        sid = "PutLogEvents"
        effect = "Allow"
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.cw_processor_lambda_name}:*"
        ]
    }
}

data "aws_iam_policy_document" "cwprocessor_sns" {
    statement {
        sid = "SNS"
        effect = "Allow"
        actions = [
            "sns:Publish"
        ]

        resources = [
            "${aws_sns_topic.kms_logging_events.arn}"
        ]
    }
}

data "aws_iam_policy_document" "cwprocessor_kinesis" {
    statement {
        sid = "Kinesis"
        effect = "Allow"
        actions = [
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:DescribeStream"
        ]

        resources = [
            "${aws_kinesis_stream.datastream.arn}"
        ]
    }
}

resource "aws_iam_role_policy" "cwprocessor_cloudwatch" {
    name = "CloudWatch"
    role = "${aws_iam_role.cloudwatch_processor.id}"
    policy = "${data.aws_iam_policy_document.cwprocessor_cloudwatch.json}"
}

resource "aws_iam_role_policy" "cwprocessor_dynamodb" {
    name = "DynamoDb"
    role = "${aws_iam_role.cloudwatch_processor.id}"
    policy = "${data.aws_iam_policy_document.lambda_dynamodb.json}"
}

resource "aws_iam_role_policy" "cwprocessor_kms" {
    name = "KMS"
    role = "${aws_iam_role.cloudwatch_processor.id}"
    policy = "${data.aws_iam_policy_document.lambda_kms.json}"
}

resource "aws_iam_role_policy" "cwprocessor_sns" {
    name = "KMS"
    role = "${aws_iam_role.cloudwatch_processor.id}"
    policy = "${data.aws_iam_policy_document.cwprocessor_sns.json}"
}

resource "aws_iam_role_policy" "cwprocessor_kinesis" {
    name = "Kinesis"
    role = "${aws_iam_role.cloudwatch_processor.id}"
    policy = "${data.aws_iam_policy_document.cwprocessor_kinesis.json}"
}

# lambda for creating cloudwatch metrics and events
resource "aws_lambda_function" "event_processor" {
    count = "${var.kmslogging_service_enabled}"
    s3_bucket = "${data.aws_s3_bucket.lambda.id}"
    s3_key = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

    lifecycle {
        ignore_changes = ["s3_key", "last_modified"]
    }

    function_name = "${local.event_processor_lambda_name}"
    description = "18F/identity-lambda-functions: KMS Log Event Processor"
    role = "${aws_iam_role.event_processor.arn}"
    handler = "main.Functions::KMSEventHandler.process"  #TODO Verify
    runtime = "ruby2.5"
    timeout = 30 # seconds

    environment {
        variables = {
            DEBUG = "${var.kmslog_lambda_debug ? "1" : ""}"
            LOG_LEVEL = "0"
            ENV_NAME = "${var.env_name}"
        }
    }

    tags {
        source_repo = "https://github.com/18F/identity-lambda-functions"
        environment = "${var.env_name}"
    }
}

resource "aws_lambda_event_source_mapping" "event_processor" {
    count = "${var.kmslogging_service_enabled}"
    event_source_arn = "${aws_sqs_queue.kms_cloudwatch_events.arn}"
    function_name = "${aws_lambda_function.event_processor.arn}"
}

resource "aws_iam_role" "event_processor" {
    name = "${local.event_processor_lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

data "aws_iam_policy_document" "event_processor_cloudwatch" {
    statement {
        sid = "CreateLogGroup"
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        ]
    }
    statement {
        sid = "PutLogEvents"
        effect = "Allow"
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.event_processor_lambda_name}:*"
        ]
    }
}

data "aws_iam_policy_document" "event_processor_cloudwatch_events" {
    statement {
        sid = "CloudWatchEvents"
        effect = "Allow"
        actions = [
            "events:PutEvents"
        ]

        resources = [
            "*"
        ]
    }
}

data "aws_iam_policy_document" "event_processor_cloudwatch_metrics" {
    statement {
        sid = "CloudWatchMetrics"
        effect = "Allow"
        actions = [
            "cloudwatch:PutMetricData"
        ]

        resources = [
            "*"
        ]
    }
}

data "aws_iam_policy_document" "event_processor_sqs" {
    statement {
        sid = "SQS"
        effect = "Allow"
        actions = [
            "sqs:DeleteMessage",
            "sqs:ChangeMessageVisibility",
            "sqs:ReceiveMessage",
            "sqs:SendMessage",
            "sqs:GetQueueAttributes"
        ]

        resources = [
            "${aws_sqs_queue.kms_cloudwatch_events.arn}"
        ]
    }
}

resource "aws_iam_role_policy" "event_processor_cloudwatch" {
    name = "CloudWatch"
    role = "${aws_iam_role.event_processor.id}"
    policy = "${data.aws_iam_policy_document.event_processor_cloudwatch.json}"
}

resource "aws_iam_role_policy" "event_processor_cloudwatch_events" {
    name = "CloudWatchEvents"
    role = "${aws_iam_role.event_processor.id}"
    policy = "${data.aws_iam_policy_document.event_processor_cloudwatch_events.json}"
}

resource "aws_iam_role_policy" "event_processor_cloudwatch_metrics" {
    name = "CloudWatchMetrics"
    role = "${aws_iam_role.event_processor.id}"
    policy = "${data.aws_iam_policy_document.event_processor_cloudwatch_metrics.json}"
}

resource "aws_iam_role_policy" "event_processor_kms" {
    name = "KMS"
    role = "${aws_iam_role.event_processor.id}"
    policy = "${data.aws_iam_policy_document.lambda_kms.json}"
}

resource "aws_iam_role_policy" "event_processor_sqs" {
    name = "SQS"
    role = "${aws_iam_role.event_processor.id}"
    policy = "${data.aws_iam_policy_document.event_processor_sqs.json}"
}
