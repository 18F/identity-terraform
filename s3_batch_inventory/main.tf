# -- Variables --
variable "bucket_list" {
  description = "List of bucket names to have inventory configurations added to them."
  type        = list(string)
  default     = []
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "inventory_bucket_sse" {
  type        = string
  description = "SSE algorithm used by the S3 Inventory bucket specified by var.inventory_bucket_arn"
  default     = "sse_s3"

  validation {
    condition     = contains(["sse_s3", "sse_kms"], var.inventory_bucket_sse)
    error_message = "var.inventory_bucket_sse must be 'sse_s3' or 'sse_kms'"
  }
}

variable "inventory_bucket_kms_key_id" {
  type        = string
  description = "KMS key used by the S3 Inventory bucket if var.inventory_bucket_sse = 'sse_kms'"
  default     = ""

  validation {
    condition = var.inventory_bucket_sse == "sse_kms" ? can(regex(
      "^arn:aws:kms:::[a-zA-Z0-9.-]+$", var.inventory_bucket_kms_key_id
    )) : true
    error_message = "var.inventory_bucket_kms_key_id must be a valid KMS ARN if var.inventory_bucket_sse is 'sse_kms'"
  }
}

# -- Resources --

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
      bucket_arn = var.inventory_bucket_arn

      encryption {
        dynamic "sse_s3" {
          for_each = var.inventory_bucket_sse == "sse_s3" ? [1] : []
          content {}
        }

        dynamic "sse_kms" {
          for_each = var.inventory_bucket_sse == "sse_kms" ? [1] : []
          content {
            key_id = var.inventory_bucket_kms_key_id
          }
        }
      }
    }
  }

  optional_fields = [
    "LastModifiedDate",
    "ETag",
    "EncryptionStatus",
  ]
}
