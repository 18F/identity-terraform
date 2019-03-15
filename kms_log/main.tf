data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "ct_log_bucket"
{
    bucket = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
}

data "aws_kms_key" "application"
{
    key_id = "alias/${var.env_name}-login-dot-gov-keymaker"
}

locals {
    kms_alias = "alias/${var.env_name}-kms-logging"
    dynamodb_table_name = "${var.env_name}-kms-logging"
    kinesis_stream_name = "${var.env_name}-kms-app-events"
    event_rule_name = "${var.env_name}-decryption-events"
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
                "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/${local.event_rule_name}"
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
    name = "${local.event_rule_name}"
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

resource "aws_sqs_queue_policy" "kms_cloudwatch_events"{
    queue_url = "${aws_sqs_queue.kms_cloudwatch_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_cw_events_policy.json}"
}

# policy for queue that receives events for cloudwatch metrics
data "aws_iam_policy_document" "sqs_kms_cw_events_policy" {
    statement {
        sid = "Allow SNS"
        effect = "Allow"
        actions = ["sqs:SendMessage"]
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
