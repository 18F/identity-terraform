resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket_name
  region        = var.region
  force_destroy = var.force_destroy

  tags = var.bucket_tags
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  count = var.block_public_access ? 1 : 0

  bucket                  = aws_s3_bucket.bucket.id
  region                  = var.region
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_inventory" "bucket" {
  for_each = anytrue([
    var.inventory_bucket_arn == "",
    length(var.inventory_config) == 0
  ]) ? {} : var.inventory_config

  bucket = var.bucket_name
  region = var.region

  name                     = each.key
  included_object_versions = each.value.included_versions

  dynamic "filter" {
    for_each = each.value.filter_prefix == null ? [] : [each.value.filter_prefix]
    iterator = filter_prefix

    content {
      prefix = filter_prefix.value
    }
  }

  schedule {
    frequency = each.value.frequency
  }

  destination {
    bucket {
      format     = each.value.format
      bucket_arn = var.inventory_bucket_arn
      account_id = try(each.value.bucket_account_id, data.aws_caller_identity.current.account_id)
      prefix     = try(each.value.inventory_prefix, null)

      encryption {
        dynamic "sse_s3" {
          for_each = each.value.bucket_sse == "sse_s3" ? [1] : []
          content {}
        }

        dynamic "sse_kms" {
          for_each = each.value.bucket_sse == "sse_kms" ? [1] : []
          content {
            key_id = each.value.bucket_kms_key_id
          }
        }
      }
    }
  }

  optional_fields = each.value.optional_fields

  depends_on = [
    aws_s3_bucket_public_access_block.bucket
  ]
}

resource "aws_s3_bucket_logging" "bucket" {
  count = var.logging_bucket_id == "" ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  region = var.region

  target_bucket = var.logging_bucket_id
  target_prefix = "${aws_s3_bucket.bucket.id}/"
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  region = var.region
  policy = data.aws_iam_policy_document.s3_require_secure_connections.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  region = var.region

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.sse_config.algorithm == "aws:kms" ? (
        var.sse_config.custom_kms_key == "" ? (
          var.sse_config.create_kms_key ? aws_kms_key.bucket[0].key_id : ""
        ) : var.sse_config.custom_kms_key
      ) : ""
      sse_algorithm = var.sse_config.algorithm
    }

    blocked_encryption_types = var.sse_config.blocked_encryption_types
    bucket_key_enabled       = var.sse_config.bucket_key_enabled
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  count = var.versioning_status == "" ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  region = var.region

  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  count = var.object_ownership == "" ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  region = var.region

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "bucket" {
  count = anytrue([var.bucket_acl == "", var.object_ownership == ""]) ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  region = var.region
  acl    = var.bucket_acl

  depends_on = [
    aws_s3_bucket_ownership_controls.bucket
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count = length(var.lifecycle_rules) == 0 ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  region = var.region

  transition_default_minimum_object_size = var.lifecycle_minimum_object_size

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value["status"]

      filter {
        prefix = rule.value["filter_prefix"]
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try([rule.value["abort_days_after_initiation"]], [])
        iterator = abort_days

        content {
          days_after_initiation = abort_days.value
        }
      }

      dynamic "transition" {
        for_each = can(rule.value["transition"]) ? [rule.value["transition"]] : []
        content {
          days          = can(transition.value["date"]) ? "" : transition.value["days"]
          date          = can(transition.value["days"]) ? "" : transition.value["date"]
          storage_class = transition.value["storage_class"]
        }
      }

      dynamic "expiration" {
        for_each = can(rule.value["expiration"]) ? [rule.value["expiration"]] : []
        content {
          days = can(expiration.value["date"]) ? "" : expiration.value["days"]
          date = can(expiration.value["days"]) ? "" : expiration.value["date"]

          expired_object_delete_marker = anytrue([
            can(expiration.value["date"]),
            can(expiration.value["days"])
          ]) ? null : expiration.value["expired_object_delete_marker"]
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try([rule.value["noncurrent_version_expiration"]], [])
        iterator = nc_expiration

        content {
          newer_noncurrent_versions = try(nc_expiration.value["newer_noncurrent_versions"], null)
          noncurrent_days           = nc_expiration.value["noncurrent_days"]
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try([rule.value["noncurrent_version_transition"]], [])
        iterator = nc_transition

        content {
          newer_noncurrent_versions = try(nc_transition.value["newer_noncurrent_versions"], null)
          noncurrent_days           = nc_transition.value["noncurrent_days"]
          storage_class             = nc_transition.value["storage_class"]
        }
      }
    }
  }
}
