data "aws_caller_identity" "current" {}

locals {
    rotation_lambda_name = "${var.env_name}-${var.password_rotation_lambda_name}"
    secret_name = "${var.env_name}/${var.secret_name}"
}

resource "aws_security_group" "lambda" {
    count = "${var.password_rotation_lambda_vpc_id != "" ? 1 : 0}"
    name = "${local.rotation_lambda_name}"
    description = "Secret rotation lambda"
    vpc_id = "${var.password_rotation_lambda_vpc_id}"
}

resource "aws_lambda_function" "lambda" {
    s3_bucket = "${var.lambda_source_bucket}"
    s3_key = "${var.password_rotation_lambda_source_key}"
    function_name = "${local.rotation_lambda_name}"
    description = "Lambda for password rotation"
    memory_size = "${var.password_rotation_lambda_memory}"
    timeout = "${var.password_rotation_lambda_timeout}"
    role = "${aws_iam_role.lambda.arn}"
    handler = "${var.password_rotation_lambda_handler}"
    runtime = "${var.password_rotation_lambda_runtime}"

    environment {
        variables = {
            SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.region}.amazonaws.com"
        }
    }

    vpc_config {
        subnet_ids = ["${var.password_rotation_lambda_subnets}"]
        security_group_ids = ["${aws_security_group.lambda.id}"]
    }
}

resource "aws_secretsmanager_secret" "secret_with_rotation" {
    depends_on = [
        "aws_lambda_function.lambda"
    ]
    name = "${local.secret_name}"
    description = "${var.secret_description}"
    rotation_lambda_arn = "${aws_lambda_function.lambda.arn}"
    kms_key_id = "${var.secret_kms_key_id}"
    recovery_window_in_days = "${var.secret_recovery_window}"
    
    rotation_rules {
        automatically_after_days = "${var.secret_rotation_days}"
    }

    tags {
        environment = "${var.env_name}"
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
    name = "${local.rotation_lambda_name}-execution"
    assume_role_policy = "${data.aws_iam_policy_document.assume-role.json}"
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
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.rotation_lambda_name}:*"
      ]
  }
}

resource "aws_iam_role_policy" "logging" {
  name = "logging"
  role = "${aws_iam_role.lambda.id}"
  policy = "${data.aws_iam_policy_document.logging.json}"
}

data "aws_iam_policy_document" "EC2" {
    statement {
        sid = "EC2"
        effect = "Allow"
        actions = [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DetachNetworkInterface"
        ]
        resources = [
            "*"
        ]
    }
}

resource "aws_iam_role_policy" "EC2" {
    name = "EC2"
    role = "${aws_iam_role.lambda.id}"
    policy = "${data.aws_iam_policy_document.EC2.json}"
}

data "aws_iam_policy_document" "secretsmanager" {
    statement {
        sid = "secretsmanager"
        effect = "Allow"
        actions = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:UpdateSecretVersionStage"
        ]
        resources = [
            "${aws_secretsmanager_secret.secret_with_rotation.arn}"

        ]
        condition {
            test = "StringEquals"
            variable = "secretsmanager:resource/AllowRotationLambdaArn"
            values = [
                "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${local.rotation_lambda_name}"
            ]
        }
    }

    statement {
        sid = "secretsmanagerrandom"
        effect = "Allow"
        actions = [
            "secretsmanager:GetRandomPassword"
        ]
        resources = [
            "*"
        ]
    }
}

resource "aws_iam_role_policy" "secretsmanager" {
    name = "secretsmanager"
    role = "${aws_iam_role.lambda.id}"
    policy = "${data.aws_iam_policy_document.secretsmanager.json}"
}

resource "aws_lambda_permission" "allow_secretsmanager" {
    statement_id = "secretsmanageraccess"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda.arn}"
    principal = "secretsmanager.amazonaws.com"
}