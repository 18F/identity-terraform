# -- Variables --
variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
}

variable "region" {
  description = "AWS Region"
}

variable "remote_state_enabled" {
  description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
  default = 1
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform_locks'"
  default     = "terraform_locks"
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports in S3 Inventory bucket."
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
      "arn:aws:s3:::${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
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

# -- Locals --

locals {
  log_bucket       = "${var.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  state_bucket     = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
  inventory_bucket = "${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

# -- Resources --

# Deprecated bucket 
# Delete this block
# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "${var.bucket_name_prefix}.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "log-delivery-write"
  policy = ""

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "expirelogs"
    enabled = true

    prefix = "/"

    expiration {
      days = 1
    }
    noncurrent_version_expiration {
      days = 1
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
    prevent_destroy = false
  }
}

# Bucket used for storing S3 access logs
# do not enable logging on this bucket
resource "aws_s3_bucket" "s3-access-logs" {
  bucket = local.log_bucket
  acl    = "log-delivery-write"
  policy = ""

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expirelogs"
    enabled = true

    prefix = "/"

    transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    expiration {
      # 5 years
      days = 1825
    }
    noncurrent_version_expiration {
      days = 1825
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "tf-state" {
  count = var.remote_state_enabled

  bucket = local.state_bucket
  acl    = "private"
  policy = ""
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.s3-access-logs.id
    target_prefix = "${local.state_bucket}/"
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

resource "aws_dynamodb_table" "tf-lock-table" {
  count = var.remote_state_enabled

  name           = var.state_lock_table
  read_capacity  = 2
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# bucket to collect S3 Inventory reports
resource "aws_s3_bucket" "inventory" {
  bucket        = local.inventory_bucket
  force_destroy = true
  policy        = data.aws_iam_policy_document.inventory_bucket_policy.json

  logging {
    target_bucket = aws_s3_bucket.s3-access-logs.id
    target_prefix = "${local.inventory_bucket}/"
  }

  versioning {
    enabled = true
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


module "s3_config" {
  for_each = var.remote_state_enabled == 1 ? toset(["s3-access-logs", "tf-state"]) : toset(["s3-access-logs"])
  source = "github.com/18F/identity-terraform//s3_config?ref=4c97667be90e651be4f800b34d964a83368a001c"
  depends_on = [aws_s3_bucket.s3-access-logs]

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = each.key
  region               = var.region
  inventory_bucket_arn = aws_s3_bucket.inventory.arn
}

# -- Outputs --
output "s3_log_bucket" {
  value = aws_s3_bucket.s3-logs.id
}

output "s3_access_log_bucket" {
  value = aws_s3_bucket.s3-access-logs.id
}

output "inventory_bucket_arn" {
  value = aws_s3_bucket.inventory.arn
}
