# Bucket used for storing S3 access logs
# do not enable logging on this bucket
resource "aws_s3_bucket" "s3_access_logs" {
  bucket = "${var.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id
  policy = data.aws_iam_policy_document.s3_reject_non_secure_operations[aws_s3_bucket.s3_access_logs.arn].json
}

resource "aws_s3_bucket_versioning" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.s3_access_logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "expirelogs"
    status = "Enabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 0
      storage_class   = "INTELLIGENT_TIERING"
    }

    expiration {
      # 5 years
      days = 1825
    }

    noncurrent_version_expiration {
      noncurrent_days = 1825
    }
  }
}
