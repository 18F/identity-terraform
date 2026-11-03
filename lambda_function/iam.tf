locals {
  lambda_role_name = var.lambda_iam_role_name != null ? var.lambda_iam_role_name : var.function_name
  role_name_prefix = substr(var.role_name_prefix, 0, 38)
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch" {
  source_policy_documents = length(var.lambda_iam_policy_document) > 0 ? [var.lambda_iam_policy_document] : []

  statement {
    sid    = "CreateLogStreamAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda.arn,
      "${aws_cloudwatch_log_group.lambda.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_cloudwatch" {
  name = "lambda-cloudwatch-${(var.role_name_prefix == null ? local.lambda_role_name : local.role_name_prefix)}"

  policy = data.aws_iam_policy_document.lambda_cloudwatch.json
}

resource "aws_iam_role" "lambda" {
  name               = var.role_name_prefix == null ? local.lambda_role_name : null
  name_prefix        = var.role_name_prefix != null ? local.role_name_prefix : null
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = var.iam_role_description
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.lambda_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  count      = var.insights_layer_enabled ? 1 : 0
  role       = aws_iam_role.lambda.id
  policy_arn = module.lambda_insights[0].iam_policy_arn
}
