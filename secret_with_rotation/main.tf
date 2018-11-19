resource "aws_secretsmanager_secret" "secret_with_rotation" {
    name = "${var.env_name}-${var.secret_name}"
    description = "${var.secret_description}"
    rotation_lambda_arn = "${var.secret_rotation_lambda_arn}"
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

resource "aws_iam_role_policy_attachment" "EC2" {
    role       = "${var.password_rotation_lambda_role_arn}"
    policy_arn = "${aws_iam_policy.EC2.arn}"
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
            "arn:aws:secretsmanager:us-east-1:540430061122:secret:dev/redshift/*" # fix
        ]
        condition {
            test = "StringEquals"
            variable = "secretsmanager:resource/AllowRotationLambdaArn"
            values = [
                "arn:aws:lambda:us-east-1:540430061122:function:cloud9-rstest2-rstest2-CSTT3JTRKWWG" #fix
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

resource "aws_iam_role_policy_attachment" "secretsmanager" {
    role       = "${var.password_rotation_lambda_role_arn}"
    policy_arn = "${aws_iam_policy.secretsmanager.arn}"
}
