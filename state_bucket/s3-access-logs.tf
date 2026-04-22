# Bucket used for storing S3 access logs
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

    blocked_encryption_types = var.s3_blocked_encryption_types
    bucket_key_enabled       = var.s3_bucket_key_enabled
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

module "s3_config_s3_access_logs" {
  source = "github.com/18F/identity-terraform//s3_config?ref=34b2514f6a21c21902c0c75cbf4a2c34d07da1fa"
  #source = "../s3_config"

  bucket_name_override = aws_s3_bucket.s3_access_logs.id
  region               = var.region
  inventory_bucket_arn = aws_s3_bucket.inventory.arn
  logging_bucket_id    = aws_s3_bucket.s3_access_logs.id # cancels itself out + disables logging on this bucket!
}

moved {
  from = module.s3_config["s3-access-logs"]
  to   = module.s3_config_s3_access_logs
}
