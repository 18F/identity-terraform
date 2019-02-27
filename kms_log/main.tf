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
}

# create cmk for kms logging solution
resource "aws_kms_key" "kms_logging" {
    description = "KMS logging key"
    enable_key_rotation = true
    tags {
       Name = "${var.env_name} KMS Logging Key"
       environment = "${var.env_name}" 
    }
}

resource "aws_kms_alias" "kms_logging" {
    name = "${local.kms_alias}"
    target_key_id = "${aws_kms_key.kms_logging.key_id}"
}

# create queue to receive cloudwatch events
resource "aws_sqs_queue" "dead_letter" {
    name = "${var.env}-kms-dead-letter"
    kms_master_key_id = "${local.kms_alias}"
    kms_data_key_reuse_period_seconds = 600
    redrive_policy = ""
}

resource "aws_sqs_queue" "kms_ct_events" {
    name = "${var.env_name}-kms-ct-events"
    delay_seconds = 60
    max_message_size = 2048
    kms_data_key_reuse_period_seconds = 600
}

resource "aws_sqs_queue_policy" "default"{
    queue_url = "${aws_sqs_queue.kms_ct_events.id}"
    policy = "${data.aws_iam_policy_document.sqs_kms_ct_events_policy.json}"
}

data "aws_iam_policy_document" "sqs_kms_ct_events_policy" {
    statement {
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
                "${aws_sqs_queue.kms_ct_events.arn}"
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
            "keyId": [
                "alias/"${var.env_name}-login-dot-gov-keymaker"
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

# create lambda for ct events

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
        type = "BOOL"
    }

    attribute {
        name = "CTEvent"
        type = "S"
    }

    attribute {
        name = "AppEvent"
        type = "S"
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
        AttributeName = "ttl"
    }

  tags = {
    Name = "${local.dynamodb_table_name}"
    environment = "${var.env_name}"
  }
}

# create lambda for kms.log events

