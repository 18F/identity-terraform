# -- Data Sources --
data "aws_caller_identity" "current" {
}

# -- Resources --
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = local.bucket_fullname
  region = var.region

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_inventory" "daily" {
  bucket = local.bucket_fullname
  region = var.region

  name                     = "FullBucketDailyInventory"
  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "Parquet"
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

  optional_fields = var.optional_fields

  depends_on = [
    aws_s3_bucket_public_access_block.public_block
  ]
}

resource "aws_s3_bucket_logging" "access_logging" {
  count = var.logging_bucket_id == local.bucket_fullname ? 0 : 1 # don't create a logging config for the logging bucket!

  bucket = local.bucket_fullname
  region = var.region

  target_bucket = var.logging_bucket_id
  target_prefix = "${local.bucket_fullname}/"
}
