data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
    bucket = "login-gov-${var.bucket_name}-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}"
    acl    = "private"
    policy = ""

    logging {
        target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    }

    lifecycle_rule {
        id      = "lifecycle"
        enabled = true

        expiration {
            days = 180
        }
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "aws:kms"
                kms_master_key_id = "${var.kms_key_id}"
            }
        }
    }

    tags {
        environment = "${var.env_name}"
    }
}