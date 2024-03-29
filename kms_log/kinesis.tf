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
data "aws_iam_policy_document" "assume_role_kinesis" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

moved {
  from = data.aws_iam_policy_document.assume_role
  to   = data.aws_iam_policy_document.assume_role_kinesis
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
  assume_role_policy = data.aws_iam_policy_document.assume_role_kinesis.json
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

  depends_on = [
    aws_kinesis_stream.datastream
  ]
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

# create destination policy
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
