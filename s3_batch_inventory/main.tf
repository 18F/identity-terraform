# -- Variables --
variable "bucket_prefix" {
  description = "First substring in S3 bucket name of $bucket_prefix.s3-inventory.$account_id-$region"
  type        = string
}

variable "bucket_list" {
  description = "List of bucket names to have inventory configurations added to them."
  type        = any
  default     = {}
}

variable "log_bucket" {
  description = "Name of the bucket used for S3 logging."
  type        = string
  default     = "s3-logs"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  statement {
    sid     = replace(statement.value, "/[.-]/", "")
    actions = [
      "s3:PutObject"
    ]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = [
      "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = var.bucket_list
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# -- Resources --

resource "aws_s3_bucket" "inventory_bucket" {
  bucket = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  force_destroy = true
  policy = data.aws_iam_policy_document.inventory_bucket_policy

  logging {
    target_bucket = var.log_bucket
    target_prefix = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_inventory" "daily_inventory" {
  for_each = toset(var.bucket_list)

  bucket = each.key
  name = "FullBucketDailyInventory"
  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.inventory.arn
    }
  }
}
