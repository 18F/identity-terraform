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