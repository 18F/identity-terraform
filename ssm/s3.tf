data "aws_iam_policy_document" "s3_require_secure_connections" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.ssm_logs.arn,
      "${aws_s3_bucket.ssm_logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket" "ssm_logs" {
  bucket = join(".", [
    "${var.bucket_name_prefix}.${var.env_name}-ssm-logs",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  region        = var.region
  force_destroy = var.force_destroy_ssm_logs_bucket

  tags = {
    environment = var.env_name
  }
}

resource "aws_s3_bucket_policy" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region
  policy = data.aws_iam_policy_document.s3_require_secure_connections.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.ssm.key_id
      sse_algorithm     = "aws:kms"
    }

    blocked_encryption_types = var.s3_blocked_encryption_types
    bucket_key_enabled       = var.s3_bucket_key_enabled
  }
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.ssm_logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  region = var.region

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "expire"
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
      days = 2190
    }

    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "ssm_logs_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=7a090cdc3647c08eb511b49e328caf33deef4f24"
  #source = "../s3_config"

  bucket_name          = aws_s3_bucket.ssm_logs.id
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
}
