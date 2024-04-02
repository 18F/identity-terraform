## Data Sources

data "aws_caller_identity" "current" {
}

data "aws_iam_policy" "insights" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
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

data "aws_iam_policy_document" "assume_role_lambda" {
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

moved {
  from = data.aws_iam_policy_document.assume-role
  to   = data.aws_iam_policy_document.assume_role_lambda
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

## Resources

resource "null_resource" "kms_log_found" {
  triggers = {
    kms_log = "${var.env_name}_/srv/idp/shared/log/kms.log"
  }
}

# DynamoDB table for event correlation
resource "aws_dynamodb_table" "kms_events" {
  name         = "${var.env_name}-kms-logging"
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
    Name        = "${var.env_name}-kms-logging"
    environment = var.env_name
  }
}

# create CMK for KMS logging solution
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
  name          = "alias/${var.env_name}-kms-logging"
  target_key_id = aws_kms_key.kms_logging.key_id
}

# SNS topic for metrics and events sent by Lambda functions
resource "aws_sns_topic" "kms_logging_events" {
  name              = "${var.env_name}-kms-logging-events"
  display_name      = "KMS Events"
  kms_master_key_id = aws_kms_alias.kms_logging.name
}

# subscription for cloudwatch metrics queue to the sns topic
resource "aws_sns_topic_subscription" "kms_events_sqs_cw_target" {
  topic_arn = aws_sns_topic.kms_logging_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.kms_cloudwatch_events.arn
}
