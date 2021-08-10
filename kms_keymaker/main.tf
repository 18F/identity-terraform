# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "kms" {
  # Allow root users in
  statement {
    actions = [
      "kms:*",
    ]
    principals {
      type        = "AWS"
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
      type        = "AWS"
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
      type        = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sns.amazonaws.com",
      ]
    }
  }
}

# -- Resources --

resource "aws_kms_key" "login-dot-gov-keymaker" {
  enable_key_rotation = true
  description         = "${var.env_name}-login-dot-gov-keymaker"
  policy              = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "login-dot-gov-keymaker-alias" {
  name          = "alias/${var.env_name}-login-dot-gov-keymaker"
  target_key_id = aws_kms_key.login-dot-gov-keymaker.key_id
}

data "aws_kms_key" "application" {
  key_id = aws_kms_key.login-dot-gov-keymaker.key_id
}

# cloudwatch event rule to capture cloudtrail kms decryption events
# this filter will only capture events where the
# encryption context is set and has the values of
# password-digest or pii-encryption
resource "aws_cloudwatch_event_rule" "decrypt" {
  name        = "${var.env_name}-decryption-events"
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

# SNS topic to send decryption events to SQS
resource "aws_sns_topic" "kms_events" {
  name = "${var.env_name}-decryption-events"
}

# endpoint subscription for SNS->SQS (for multi-region support)
resource "aws_sns_topic_subscription" "kms_ct_sqs" {
  topic_arn = aws_sns_topic.kms_events.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}

# sets the receiver of the cloudwatch events
# to the SNS topic
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.decrypt.name
  target_id = "${var.env_name}-sns"
  arn       = aws_sns_topic.kms_events.arn
}

data "aws_iam_policy_document" "kms_events_topic_policy" {
  policy_id = "kms_ct_sqs"

  statement {
    sid = "KMSCTSQS"
    actions = [
      "SNS:Publish",
    ]

#    condition {
#      test     = "StringLike"
#      variable = "aws:SourceArn"
#      values = [aws_cloudwatch_event_rule.decrypt.arn]
#    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.kms_events.arn
    ]
  }
}

resource "aws_sns_topic_policy" "kms_events" {
  arn = aws_sns_topic.kms_events.arn

  policy = data.aws_iam_policy_document.kms_events_topic_policy.json
}
