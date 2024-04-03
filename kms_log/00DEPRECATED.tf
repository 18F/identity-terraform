############## RESOURCES TO BE DEPRECATED/REMOVED ##############

# These are being left here for overlap between creating the new/properly-formatted
# resources, and the existing ones, to prevent a lapse in permissions/policies
# (thus potentially cutting off resource access in the process).
# TO BE REMOVED in a subsequent PR.

resource "aws_iam_policy" "lambda_to_cloudwatch_policy" {
  name = "${var.env_name}_unmatched_lambda_to_cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.slack_processor_lambda_name}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "sqs_to_lambda_policy" {
  name = "${var.env_name}_unmatched_sqs_to_lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowManagingSQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [
          aws_sqs_queue.unmatched.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_to_lambda" {
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.sqs_to_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_to_cloudwatch" {
  role       = aws_iam_role.slack_processor.name
  policy_arn = aws_iam_policy.lambda_to_cloudwatch_policy.arn
}

############## RESOURCES BEING MOVED/RENAMED ##############

moved {
  from = aws_iam_role_policy.lambda_kms
  to   = aws_iam_role_policy.slack_processor_kms
}

moved {
  from = aws_iam_role_policy.ctprocessor_cloudwatch
  to   = aws_iam_role_policy.ctprocessor
}

moved {
  from = aws_iam_role_policy.ctrequeue_cloudwatch
  to   = aws_iam_role_policy.ctrequeue
}

moved {
  from = aws_iam_role_policy.cwprocessor_cloudwatch
  to   = aws_iam_role_policy.cwprocessor
}

moved {
  from = aws_iam_role_policy.event_processor_cloudwatch
  to   = aws_iam_role_policy.event_processor
}
