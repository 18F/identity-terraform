locals {
  lambda_role_name = var.role_name_prefix == null ? (
    var.lambda_iam_role_name != null ? var.lambda_iam_role_name : var.function_name
  ) : null
  role_name_prefix = var.role_name_prefix != null ? substr(var.role_name_prefix, 0, 38) : null
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.lambda_role_name
  name_prefix        = local.role_name_prefix
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = var.iam_role_description

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "lambda" {
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

resource "aws_iam_role_policy" "lambda" {
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.lambda.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  count      = var.insights_enabled ? 1 : 0
  role       = aws_iam_role.lambda.id
  policy_arn = module.lambda_insights[0].iam_policy_arn
}
