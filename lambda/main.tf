resource "aws_lambda_function" "lambda" {
  s3_bucket        = "${var.source_bucket_name}"
  s3_key           = "${var.source_key}"
  function_name    = "${var.env_name}-${var.lambda_name}"
  description      = "${var.lambda_description}"
  memory_size      = "${var.lambda_memory}"
  timeout          = "${var.lambda_timeout}"
  role             = "${var.lambda_role_arn}"
  handler          = "${var.lambda_handler}"
  source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  runtime          = "${var.lambda_runtime}"
}

data "aws_iam_policy_document" "logging" {
  statement {
    sid    = "CreateLogGroup"
    effect = "Allow"

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
  statement {
      sid = "PutLogEvents"
      effect = "Allow"

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

resource "aws_iam_policy" "lambda" {
    name = "${var.env_name}-${var.lambda_name}-policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.logging.json}"
}

resource "aws_iam_role" "lambda" {
    name = "${var.env_name}-${var.lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

resource "aws_iam_role_policy_attachment" "lambda" {
    role = "${aws_iam_role.lambda.name}"
    policy_arn = "${aws_iam_policy.lambda.arn}"
}