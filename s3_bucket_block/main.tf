# -- Variables --
variable "bucket_prefix" {
  description = "First substring in S3 bucket name of $bucket_prefix.$bucket_name.$account_id-$region"
  type        = string
}

variable "bucket_data" {
  description = "Map of bucket names and their configuration blocks."
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

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "optional_fields" {
  description = "List of optional data fields to collect in S3 Inventory reports."
  type = list(string)
  default = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier",
  ]
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

# -- Resources --
resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_data

  bucket = "${var.bucket_prefix}.${each.key}.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = lookup(each.value, "acl", "private")
  policy = lookup(each.value, "policy", "")
  force_destroy = lookup(each.value, "force_destroy", true)

  logging {
    target_bucket = var.log_bucket
    target_prefix = "${var.bucket_prefix}.${each.key}.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  versioning {
    enabled = true
  }

  dynamic "lifecycle_rule" {
    for_each = can(each.value.lifecycle_rules) ? each.value.lifecycle_rules : []
    content {
      id      = lifecycle_rule.value["id"]
      enabled = lifecycle_rule.value["enabled"]
      prefix = lifecycle_rule.value["prefix"]
      dynamic "transition" {
        for_each = lifecycle_rule.value["transitions"]
        content {
          days = transition.value["days"]
          storage_class = transition.value["storage_class"]
        }
      }
      dynamic "expiration" {
        for_each = can(lifecycle_rule.value["expiration_days"]) ? [lifecycle_rule.value["expiration_days"]] : []
        content {
          days = expiration.value
        }
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

}

resource "aws_s3_bucket_public_access_block" "block" {
  for_each = toset(
    compact(
      [ for bucket, data in var.bucket_data :
        lookup(data, "public_access_block", true) ? bucket : ""
      ]
    )
  )
  depends_on = [aws_s3_bucket.bucket]
  
  bucket                  = aws_s3_bucket.bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_inventory" "daily" {
  for_each = var.bucket_data
  depends_on = [aws_s3_bucket.bucket]

  bucket                   = aws_s3_bucket.bucket[each.key].id
  name                     = "FullBucketDailyInventory"
  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "Parquet"
      bucket_arn = var.inventory_bucket_arn
    }
  }

  optional_fields = var.optional_fields
}

# -- Outputs --
output "buckets" {
  description = "Map of the bucket names:ids created from bucket_data."
  value       = zipmap(
      sort(keys(var.bucket_data)),
      sort(values(aws_s3_bucket.bucket)[*]["id"]))
}
