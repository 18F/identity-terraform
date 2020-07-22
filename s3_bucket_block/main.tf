# -- Variables --
variable "bucket_prefix" {
  description = "First substring in S3 bucket name of $bucket_prefix.$bucket_name.$account_id-$region"
  type        = string
}

variable "bucket_data" {
  description = "Map of bucket names and their lifecycle rule blocks."
  type        = any
  default     = {}
}

variable "log_bucket" {
  description = "Substring for the name of the bucket used for S3 logging."
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

# -- Resources --
resource "aws_s3_bucket" "s3-logs" {
  bucket = "${var.bucket_prefix}.${var.log_bucket}.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expirelogs"
    enabled = true

    prefix = "/"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      # 5 years
      days = 1825
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

resource "aws_s3_bucket" "bucket" {
  for_each = var.bucket_data

  bucket = "${var.bucket_prefix}.${each.key}.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = lookup(each.value, "acl", "private")
  policy = lookup(each.value, "policy", "")
  force_destroy = lookup(each.value, "force_destroy", true)

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  for_each = toset(
    compact(
      [ for bucket, data in var.bucket_data :
        lookup(data, "public_access_block", false) ? bucket : ""
      ]
    )
  )
  
  bucket                  = aws_s3_bucket.bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -- Outputs --
output "log_bucket" {
  description = "ID of the log bucket."
  value       = aws_s3_bucket.s3-logs.id
}

output "buckets" {
  description = "IDs of the buckets created from bucket_data."
  value       = values(aws_s3_bucket.bucket)[*]["id"]
}
