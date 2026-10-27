resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = var.cloudwatch_name
  description = "Send GuardDuty findings to CW Log Groups"
  tags = {
    "Name" = var.cloudwatch_name
  }

  event_pattern = <<EOM
{
  "source" : [
    "aws.guardduty"
  ],
  "detail-type" : [
    "GuardDuty Finding"
  ]
}
EOM
}

resource "aws_cloudwatch_log_group" "guardduty_findings" {
  name              = var.log_group_id
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.prevent_tf_log_deletion
}

resource "aws_cloudwatch_event_target" "guardduty_findings" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = var.event_target_id
  arn       = aws_cloudwatch_log_group.guardduty_findings.arn
}

data "aws_iam_policy_document" "delivery_events_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
    principals {
      identifiers = [
        "delivery.logs.amazonaws.com",
        "events.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "delivery_events_logs" {
  policy_document = data.aws_iam_policy_document.delivery_events_logs.json
  policy_name     = var.publishing_policy_name
}
