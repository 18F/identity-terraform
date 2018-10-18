data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
    bucket = "login-gov-${var.bucket_name}-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}"
    acl    = "private"

    versioning {
        enabled = "true"
    }

    logging {
        target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    }

    lifecycle_rule {
        id      = "lifecycle"
        enabled = true

        transition {
            days = 720
            storage_class = "STANDARD_IA"
        }

        transition {
            days = 1080
            storage_class = "GLACIER"
        }

        expiration {
            days = 2520
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