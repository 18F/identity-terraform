data "aws_caller_identity" "current" {}

locals {
    bucket_name = "login-gov-${var.bucket_name}-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${local.bucket_name}"
    acl    = "private"
    policy = ""

    logging {
        target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
        target_prefix = "${local.bucket_name}"
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