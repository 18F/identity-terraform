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

# -- Locals --

locals {
  log_bucket   = "${var.bucket_name_prefix}.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  state_bucket = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
}

# -- Resources --

# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = local.log_bucket
  region = var.region
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "tf-state" {
  count = var.remote_state_enabled

  bucket = local.state_bucket
  region = var.region
  acl    = "private"
  policy = ""
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
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
  bucket        = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  region        = var.region
  force_destroy = true
  policy        = data.aws_iam_policy_document.inventory_bucket_policy.json

  logging {
    target_bucket = var.log_bucket
    target_prefix = "${var.bucket_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}/"
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
  for_each = toset(["s3-logs", "tf-state"])
  source = "github.com/18F/identity-terraform//s3_config?ref=b3e70684fbe69e14e6043290638b3e57194f12ac"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = each.key
  region               = var.region
  inventory_bucket_arn = aws_s3_bucket.inventory.arn
}

output "s3_log_bucket" {
  value = aws_s3_bucket.s3-logs.id
}

