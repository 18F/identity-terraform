# -- Variables --
variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
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
  default     = "s3-access-logs"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports in S3 Inventory bucket."
  type        = string
  default     = "aws:kms"
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

# -- Resources --
resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_data

  bucket = "${var.bucket_name_prefix}.${each.key}.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = lookup(each.value, "acl", "private")
  policy = lookup(each.value, "policy", "")
  force_destroy = lookup(each.value, "force_destroy", true)

  logging {
    target_bucket = var.log_bucket
    target_prefix = "${var.bucket_name_prefix}.${each.key}.${data.aws_caller_identity.current.account_id}-${var.region}/"
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
        sse_algorithm = var.sse_algorithm
      }
    }
  }

}

module "bucket_config" {
  for_each = var.bucket_data
  source = "github.com/18F/identity-terraform//s3_config?ref=cee758e3ed080b27aedc45087e8ae4d5330dd2d3"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = each.key
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
  block_public_access  = lookup(each.value, "public_access_block", true)
}

# -- Outputs --
output "buckets" {
  description = "Map of the bucket names:ids created from bucket_data."
  value       = zipmap(
      sort(keys(aws_s3_bucket.bucket)[*]),
      sort(values(aws_s3_bucket.bucket)[*]["id"]))
}
