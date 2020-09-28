# -- Variables --
variable "bucket_prefix" {
  description = "First substring in S3 bucket name of $bucket_prefix.s3-inventory.$account_id-$region"
  type        = string
}

variable "bucket_list" {
  description = "List of bucket names to have inventory configurations added to them."
  type        = list(string)
  default     = []
}

variable "log_bucket" {
  description = "Name of the bucket used for S3 logging."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"  
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports."
  type        = string
  default     = "aws:kms"
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  statement {
    sid     = "AllowInventoryBucketAccess"
    actions = [
      "s3:PutObject"
    ]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = [
      "arn:aws:s3:::${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = formatlist("arn:aws:s3:::%s", var.bucket_list)
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
resource "aws_s3_bucket" "inventory" {
  bucket        = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  region        = var.region
  force_destroy = true
  policy        = data.aws_iam_policy_document.inventory_bucket_policy.json

  logging {
    target_bucket = var.log_bucket
    target_prefix = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_inventory" "daily" {
  for_each = toset(var.bucket_list)

  bucket                   = each.key
  name                     = "FullBucketDailyInventory"
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

  optional_fields = [
    "LastModifiedDate",
    "ETag",
    "EncryptionStatus",
  ]
}

# -- Outputs --

output "inventory_bucket" {
  value = aws_s3_bucket.inventory.id
}
