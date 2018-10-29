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
            #todo add transition for previous versions to ia at 30 days
            #cleanup multipart uploads at 7 days
            days = 720
            storage_class = "STANDARD_IA"
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
        environment = "${var.env_name}"
    }
}