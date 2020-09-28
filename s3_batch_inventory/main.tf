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
    }
  }

  optional_fields = [
    "LastModifiedDate",
    "ETag",
    "EncryptionStatus",
  ]
}
