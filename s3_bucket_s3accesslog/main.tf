data "aws_caller_identity" "current" {}

locals {
    bucket_name = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${local.bucket_name}"
    acl    = "log-delivery-write"
    policy = ""

    versioning {
        enabled = "true"
    }

    lifecycle_rule {
        id      = "expirelogs"
        enabled = true

        transition {
            days = 30
            storage_class = "STANDARD_IA"
        }

        transition {
            days = 365
            storage_class = "GLACIER"
        }

        expiration {
            days = 1825
        }
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }

    tags {
        environment = "account"
    }
}

