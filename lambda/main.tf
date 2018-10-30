data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lambda" {
  s3_bucket        = "${var.source_bucket_name}"
  s3_key           = "${var.source_key}"
  function_name    = "${var.env_name}-${var.lambda_name}"
  description      = "${var.lambda_description}"
  memory_size      = "${var.lambda_memory}"
  timeout          = "${var.lambda_timeout}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "${var.lambda_handler}"
  #source_code_hash = "${base64sha256(file("${var.source_key}.zip"))}"
  runtime          = "${var.lambda_runtime}"
}

data "aws_iam_policy_document" "logging" {
  statement {
    sid    = "CreateLogGroup"
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
  statement {
      sid = "PutLogEvents"
      effect = "Allow"
      actions = [
        "logs:PutLogEvents"
      ]

      resources = [
          "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.env_name}-${var.lambda_name}"
      ]
  }
}

data "aws_iam_policy_document" "assume-role" {
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

resource "aws_iam_role" "lambda" {
    name = "${var.env_name}-lambda-${var.lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

resource "aws_iam_role_policy" "logging" {
  name = "logging"
  role = "${aws_iam_role.lambda.id}"
  policy = "${data.aws_iam_policy_document.logging.json}"
}