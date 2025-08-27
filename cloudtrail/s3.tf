data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AllowCloudTrailGetBucketAcl"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    resources = [
      aws_s3_bucket.cloudtrail.arn
    ]
  }

  statement {
    sid    = "AllowCloudTrailPutObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid    = "S3DenyNonSecureConnections"
    effect = "Deny"
    actions = [
      "s3:*",
    ]

    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }

    resources = [
      aws_s3_bucket.cloudtrail.arn,
      "${aws_s3_bucket.cloudtrail.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.s3_force_destroy
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_sse_algorithm
      kms_master_key_id = var.s3_bucket_key_enabled && var.s3_sse_algorithm == "aws:kms" ? aws_kms_key.cloudtrail.id : null
    }

    bucket_key_enabled = var.s3_bucket_key_enabled
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "logexpire"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    expiration {
      days = 2190
    }

    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "cloudtrail_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=188d82b9e9b7423f1a71988413ec5899d31807fe"
  #source = "../s3_config"

  bucket_name_override = aws_s3_bucket.cloudtrail.id
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
}
