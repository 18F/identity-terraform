data "aws_iam_policy_document" "cwprocessor" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.cloudwatch_processor.arn,
      "${aws_cloudwatch_log_group.cloudwatch_processor.arn}:*"
    ]
  }
  statement {
    sid    = "cwprocessorSNS"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.kms_logging_events.arn,
    ]
  }
  statement {
    sid    = "Kinesis"
    effect = "Allow"
    actions = [
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:DescribeStream",
    ]

    resources = [
      aws_kinesis_stream.datastream.arn,
    ]
  }
}

resource "aws_iam_role" "cloudwatch_processor" {
  name               = "${local.cw_processor_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "cwprocessor" {
  name   = "cwprocessor"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.cwprocessor.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "cwprocessor_dynamodb" {
  name   = "cwprocessor_dynamodb"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_iam_role_policy" "cwprocessor_kms" {
  name   = "cwprocessor_kms"
  role   = aws_iam_role.cloudwatch_processor.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

resource "aws_iam_role_policy_attachment" "cwprocessor_insights" {
  role       = aws_iam_role.cloudwatch_processor.id
  policy_arn = data.aws_iam_policy.insights.arn
}

# manage log group in Terraform
resource "aws_cloudwatch_log_group" "cloudwatch_processor" {
  name              = "/aws/lambda/${local.cw_processor_lambda_name}"
  retention_in_days = var.cloudwatch_retention_days
}

resource "aws_lambda_function" "cloudwatch_processor" {
  filename      = var.lambda_kms_cw_processor_zip
  function_name = local.cw_processor_lambda_name
  description   = "KMS CW Log Processor"
  role          = aws_iam_role.cloudwatch_processor.arn
  handler       = "main.IdentityKMSMonitor::CloudWatchKMSHandler.process"
  runtime       = "ruby3.2"
  timeout       = 120 # seconds

  layers = [
    local.lambda_insights_arn
  ]

  memory_size = var.cw_processor_memory_size

  ephemeral_storage {
    size = var.cw_processor_storage_size

  }

  environment {
    variables = {
      DEBUG               = var.kmslog_lambda_debug
      DRY_RUN             = var.kmslog_lambda_dry_run
      RETENTION_DAYS      = var.dynamodb_retention_days
      DDB_TABLE           = aws_dynamodb_table.kms_events.id
      SNS_EVENT_TOPIC_ARN = aws_sns_topic.kms_logging_events.arn
    }
  }

  tags = {
    environment = var.env_name
  }

  depends_on = [aws_cloudwatch_log_group.cloudwatch_processor]
}

module "cw-processor-github-alerts" {
  #source = "github.com/18F/identity-terraform//lambda_alerts?ref=f6bb6ede0d969ea8f62ebba3cbcedcba834aee2f"
  source = "../lambda_alerts"

  enabled              = 1
  function_name        = local.cw_processor_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 5
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.cloudwatch_processor.timeout
  treat_missing_data   = "ignore"
}

resource "aws_lambda_event_source_mapping" "cloudwatch_processor" {
  event_source_arn       = aws_kinesis_stream.datastream.arn
  function_name          = aws_lambda_function.cloudwatch_processor.arn
  starting_position      = "LATEST"
  parallelization_factor = 10
}
