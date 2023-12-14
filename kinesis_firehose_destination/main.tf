# Data Sources

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "cloudwatch_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    condition {
      test = "StringLike"
      values = [
        "arn:aws:logs:${local.region}:${var.source_account_id}:*",
        "arn:aws:logs:${local.region}:${local.dest_acct_id}:*",
      ]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_firehose_access" {
  statement {
    effect = "Allow"
    actions = [
      "firehose:*"
    ]
    resources = [
      var.firehose_arn
    ]
  }
}

data "aws_iam_policy_document" "subscription_access" {
  statement {
    sid     = "SubscriptionFilterAccess"
    actions = ["logs:PutSubscriptionFilter"]

    principals {
      type        = "AWS"
      identifiers = [var.source_account_id]
    }

    resources = [
      aws_cloudwatch_log_destination.firehose.arn
    ]
  }
}

# Resources

resource "aws_iam_role" "cloudwatch_to_kinesis" {
  name               = local.identifier_name
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume.json
}

resource "aws_iam_role_policy" "cloudwatch_firehose_access" {
  name   = "${local.identifier_name}-access"
  role   = aws_iam_role.cloudwatch_to_kinesis.id
  policy = data.aws_iam_policy_document.cloudwatch_firehose_access.json
}

resource "aws_cloudwatch_log_destination" "firehose" {
  name       = local.identifier_name
  role_arn   = aws_iam_role.cloudwatch_to_kinesis.arn
  target_arn = var.firehose_arn
}

resource "aws_cloudwatch_log_destination_policy" "subscription_access" {
  destination_name = aws_cloudwatch_log_destination.firehose.name
  access_policy    = data.aws_iam_policy_document.subscription_access.json
}
