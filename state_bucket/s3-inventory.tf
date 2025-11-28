# bucket to collect S3 Inventory reports
resource "aws_s3_bucket" "inventory" {
  bucket        = "${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_versioning" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  transition_default_minimum_object_size = "all_storage_classes_128K"

  rule {
    id     = "TierAndExpire"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "INTELLIGENT_TIERING"
    }

    expiration {
      days = 2557 # 7 years
    }

    noncurrent_version_expiration {
      noncurrent_days = 2557 # 7 years
    }
  }
}

resource "aws_s3_bucket_logging" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "${aws_s3_bucket.inventory.id}/"
}

resource "aws_s3_bucket_policy" "inventory" {
  bucket = aws_s3_bucket.inventory.id
  policy = data.aws_iam_policy_document.inventory_bucket_policy.json
}

resource "aws_s3_bucket_public_access_block" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
