moved {
  from = aws_cloudwatch_event_target.sns
  to   = aws_cloudwatch_event_target.decrypt
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

# SNS topic to send decryption events to SQS
resource "aws_sns_topic" "kms_events" {
  name = "${var.env_name}-mr-decryption-events"
}

resource "aws_sns_topic_policy" "kms_events" {
  arn = aws_sns_topic.kms_events.arn

  policy = data.aws_iam_policy_document.kms_events_topic_policy.json
}

# endpoint subscription for SNS->SQS (for multi-region support)
resource "aws_sns_topic_subscription" "kms_ct_sqs" {
  topic_arn = aws_sns_topic.kms_events.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}

# sets the receiver of the cloudwatch events
# to the SNS topic
resource "aws_cloudwatch_event_target" "decrypt" {
  rule      = aws_cloudwatch_event_rule.decrypt.name
  target_id = "${var.env_name}-sns"
  arn       = aws_sns_topic.kms_events.arn
}

# send Cloudwatch events to alarm SNS topic
resource "aws_cloudwatch_event_target" "replicate" {
  rule      = aws_cloudwatch_event_rule.replicate.name
  target_id = "${var.env_name}-sns"
  arn       = var.alarm_sns_topic_arn
}

resource "aws_cloudwatch_event_target" "update_primary_region" {
  rule      = aws_cloudwatch_event_rule.update_primary_region.name
  target_id = "${var.env_name}-sns"
  arn       = var.alarm_sns_topic_arn
}

resource "aws_cloudwatch_event_target" "mr_primary_delete_kms_key" {
  rule      = aws_cloudwatch_event_rule.mr_primary_delete_kms_key.name
  target_id = "${var.env_name}-sns"
  arn       = var.alarm_sns_topic_arn
}