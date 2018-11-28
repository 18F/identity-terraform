resource "aws_secretsmanager_secret" "secret_without_rotation" {
    name = "${var.env_name}/${var.secret_name}"
    description = "${var.secret_description}"
    kms_key_id = "${var.secret_kms_key_id}"
    recovery_window_in_days = "${var.secret_recovery_window}"

    tags {
        environment = "${var.env_name}"
    }
}