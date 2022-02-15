# -- Variables --
variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Main/second substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
  default     = ""
}

variable "bucket_name_override" {
  description = "Set this to override the normal bucket naming schema."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "optional_fields" {
  description = "List of optional data fields to collect in S3 Inventory reports."
  type        = list(string)
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

variable "block_public_access" {
  description = "Whether or not to enable the public access block for this bucket."
  type        = bool
  default     = true
}

variable "enabled" {
  description = "Whether or not this module should create resources"
  type        = bool
  default     = true
}

locals {
  bucket_fullname = var.bucket_name_override != "" ? var.bucket_name_override : join(".",
    [
      var.bucket_name_prefix,
      var.bucket_name,
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

# -- Resources --
resource "aws_s3_bucket_public_access_block" "public_block" {
  count                   = var.enabled ? 1 : 0
  bucket                  = local.bucket_fullname
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_inventory" "daily" {
  count                    = var.enabled ? 1 : 0
  depends_on               = [aws_s3_bucket_public_access_block.public_block]
  bucket                   = local.bucket_fullname
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
