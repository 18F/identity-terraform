data "aws_caller_identity" "current" {}

locals {
    lambda_function_name = "${var.env_name}-${var.lambda_name}"
}

resource "aws_lambda_function" "lambda" {
    filename = "${var.source_filename}"
    s3_bucket = "${var.source_bucket_name}"
    s3_key = "${var.source_key}"
    function_name = "${local.lambda_function_name}"
    description = "${var.lambda_description}"
    memory_size = "${var.lambda_memory}"
    timeout = "${var.lambda_timeout}"
    role = "${aws_iam_role.lambda.arn}"
    handler = "${var.lambda_handler}"
    runtime = "${var.lambda_runtime}"

    environment {
        variables = {
            SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.region}.amazonaws.com"
        }
    }
}

data "aws_iam_policy_document" "logging" {
    statement {
        sid    = "CreateLogGroup"
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*",
        ]
    }
    statement {
        sid = "PutLogEvents"
        effect = "Allow"
        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_function_name}:*"
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
    name = "${local.lambda_function_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
}

resource "aws_iam_role_policy" "logging" {
    name = "logging"
    role = "${aws_iam_role.lambda.id}"
    policy = "${data.aws_iam_policy_document.logging.json}"
}