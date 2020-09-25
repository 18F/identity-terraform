data "aws_caller_identity" "current" {
}

variable "region" {
  description = "AWS Region"
}

variable "enabled" {
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

# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "${var.bucket_name_prefix}.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
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
  count = var.enabled == 1 ? 1 : 0

  bucket = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = "private"
  policy = ""
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
    target_prefix = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}/"
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
  count = var.enabled == 1 ? 1 : 0

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

output "s3_log_bucket" {
  value = aws_s3_bucket.s3-logs.id
}

