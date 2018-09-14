resource "aws_s3_bucket" "bucket" {
    bucket = "${var.bucket_name}"
    acl    = "private"

    versioning {
        enabled = "${var.versioning_enabled}"
    }

    logging {
        target_bucket = "${aws_s3_bucket.log_bucket.id}"
        target_prefix = "log/"
    }

    lifecycle_rule {
        id      = "log"
        enabled = true

        prefix  = "log/"
        tags {
            "rule"      = "log"
            "autoclean" = "true"
        }

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
            }
        }
    }

    tags {
        Name        = "Environment"
        Environment = "${var.Environment}"
    }
}