locals {
  gd_bucket = var.bucket_name == "" ? join(".", [
    "${var.bucket_name_prefix}.${var.bucket_name}.${data.aws_caller_identity.current.account_id}-${data.aws_region.current}"
  ]) : var.bucket_name_override
}

data "aws_iam_policy_document" "guardduty_s3" {
  statement {
    sid    = "AllowGDGetBucketLocation"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${local.gd_bucket}"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = local.gd_perm_conditions
      content {
        test     = "StringEquals"
        variable = condition.value["variable"]
        values   = condition.value["values"]
      }
    }
  }

  statement {
    sid    = "AllowGDPutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.gd_bucket}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = local.gd_perm_conditions
      content {
        test     = "StringEquals"
        variable = condition.value["variable"]
        values   = condition.value["values"]
      }
    }
  }

  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.gd_bucket}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.guardduty.arn]
    }
  }
}

module "s3_bucket" {
  source   = "github.com/18F/identity-terraform//s3_bucket?ref=e2cfe09fbf9be83a12c56c01071be48e6c5bc255"
  #source = "../s3_bucket"

  bucket_name = local.gd_bucket
  force_destroy = false
  region               = data.aws_region.current
  versioning_status    = var.s3_versioning
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
  bucket_policy_doc = data.aws_iam_policy_document.guardduty_s3.json
  bucket_acl = "private"
  object_ownership = "BucketOwnerPreferred"

  sse_config = {
    algorithm          = "aws:kms"
    custom_kms_key     = aws_kms_key.guardduty.arn
    bucket_key_enabled = false
  }

  lifecycle_rules = {
    "expire" = {
      status                      = "Enabled"
      filter_prefix               = "/"
      transition = {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
      expiration = {
        days                         = 2190
      }
      noncurrent_version_expiration = {
        noncurrent_days           = 2190
      }
      noncurrent_version_transition = {
        noncurrent_days           = 0
        storage_class             = "INTELLIGENT_TIERING"
      }
    }
  }

  bucket_tags = {
    Name = local.gd_bucket
  }
}
