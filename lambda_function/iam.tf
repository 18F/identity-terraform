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
  name               = "${var.function_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
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
  policy_arn = module.lambda_insights.iam_policy_arn
}
