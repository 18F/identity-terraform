module "password_rotation_lambda" {
    source = "github.com/18F/identity-terraform//lambda?ref=2dc82332a105c47dd5695c53015bbb6b857c3016"

    env_name = "${var.env_name}"
    region = "${var.region}"
    source_bucket_name = "${var.lambda_source_bucket}"
    source_key = "${var.password_rotation_lambda_source_key}"
    lambda_name = "${var.env_name}-${var.secret_name}-password_rotation"
    lambda_description = "Function to rotate password"
    lambda_memory = "${var.password_rotation_lambda_memory}"
    lambda_timeout = "${var.password_rotation_lambda_timeout}"
    lambda_handler = "${var.password_rotation_lambda_handler}" 
    lambda_runtime = "${var.password_rotation_lambda_runtime}"
}

resource "aws_secretsmanager_secret" "secret_with_rotation" {
    name = "${var.env_name}-${var.secret_name}"
    description = "${var.secret_description}"
    rotation_lambda_arn = "${module.password_rotation_lambda.lambda_arn}"
    kms_key_id = "${var.secret_kms_key_id}"
    recovery_windows_in_days = "${var.secret_recovery_window}"
    
    rotation_rules {
        automatically_after_days = "${var.secret_rotation_days}"
    }

    tags {
        environment = "${var.env_name}"
    }
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
    role = "${module.password_rotation_lambda.lambda_role_id}"
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
                "${module.password_rotation_lambda.lambda_arn}"
            ]
        }
    }

    statement {
        sid = "secretsmanager_random"
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
    role = "${module.password_rotation_lambda.lambda_role_id}"
    policy = "${data.aws_iam_policy_document.secretsmanager.json}"
}
