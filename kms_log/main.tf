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
        sid = "Allow CloudWatch Events Access"
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

# create queue to receive cloudwatch events
resource "aws_sqs_queue" "dead_letter" {
    name = "${var.env_name}-kms-dead-letter"
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600
    message_retention_seconds = 604800 # 7 days
    tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_sqs_queue" "kms_ct_events" {
    name = "${var.env_name}-kms-ct-events"
    delay_seconds = 60
    max_message_size = 2048
    visibility_timeout_seconds = 60
    message_retention_seconds = 345600 # 4 days
    kms_master_key_id = "${aws_kms_key.kms_logging.arn}"
    kms_data_key_reuse_period_seconds = 600
    redrive_policy = <<POLICY
{
    "deadLetterTargetArn": "${aws_sqs_queue.dead_letter.arn}",
    "maxReceiveCount": 10
}
POLICY
tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_sqs_queue_policy" "default"{
    queue_url = "${aws_sqs_queue.kms_ct_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_ct_events_policy.json}"
}

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
                "${aws_cloudwatch_event_rule.decrypt.arn}"
            ]

        }
    }
}

# cloudwatch event rule to capture decryption events
resource "aws_cloudwatch_event_rule" "decrypt" {
    name = "${var.env_name}-decryption-events"
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

resource "aws_cloudwatch_event_target" "sqs" {
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
        type = "B"
    }

    global_secondary_index {
        name = "Correlated_Index"
        hash_key = "UUID"
        range_key = "Correlated"
        write_capacity = 10
        read_capacity = 10
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

resource "aws_sns_topic" "kms_logging_events" {
    name = "${var.env_name}-kms-logging-events"
    display_name = "KMS Events"
    kms_master_key_id = "${local.kms_alias}"
}

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

resource "aws_sns_topic_subscription" "kms_events_sqs_cw_target" {
    topic_arn = "${aws_sns_topic.kms_logging_events.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.kms_cloudwatch_events.arn}"
}

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

resource "aws_sns_topic_subscription" "kms_events_sqs_es_target" {
    topic_arn = "${aws_sns_topic.kms_logging_events.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.kms_elasticsearch_events.arn}"
}