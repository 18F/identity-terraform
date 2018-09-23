resource "aws_kms_key" "key" {
    description = "${var.key_description}",
    deletion_windows_in_days = 30,
    is_enabled = true,
    enable_key_rotation = true

    tags {
        Name        = "Environment"
        Environment = "${var.env_name}"
    }
}

resource "aws_kms_alias" "alias" {
  name          = "${var.env_name}/${var.key_alias}"
  target_key_id = "${aws_kms_key.key.key_id}"
}