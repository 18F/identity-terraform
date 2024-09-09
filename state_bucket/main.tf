# Bucket used for storing S3 access logs
# do not enable logging on this bucket
resource "aws_s3_bucket" "s3-access-logs" {
  bucket = local.log_bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3-access-logs" {
  bucket = aws_s3_bucket.s3-access-logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3-access-logs" {
  bucket = aws_s3_bucket.s3-access-logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3-access-logs" {
  bucket = aws_s3_bucket.s3-access-logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3-access-logs" {
  bucket = aws_s3_bucket.s3-access-logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.s3-access-logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "s3-access-logs" {
  bucket = aws_s3_bucket.s3-access-logs.id

  rule {
    id     = "expirelogs"
    status = "Enabled"

    filter {
      prefix = "/"
    }

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
      noncurrent_days = 1825
    }
  }
}

data "aws_s3_bucket" "tf-state" {
  count  = var.remote_state_enabled
  bucket = local.state_bucket
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf-state" {
  count  = var.remote_state_enabled
  bucket = data.aws_s3_bucket.tf-state[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "tf-state" {
  count  = var.remote_state_enabled
  bucket = data.aws_s3_bucket.tf-state[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "tf-state" {
  count  = var.remote_state_enabled
  bucket = data.aws_s3_bucket.tf-state[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tf-state" {
  count  = var.remote_state_enabled
  bucket = data.aws_s3_bucket.tf-state[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.tf-state]
}

resource "aws_s3_bucket_logging" "tf-state" {
  count  = var.remote_state_enabled
  bucket = data.aws_s3_bucket.tf-state[count.index].id

  target_bucket = aws_s3_bucket.s3-access-logs.id
  target_prefix = "${local.state_bucket}/"
}

# bucket to collect S3 Inventory reports
resource "aws_s3_bucket" "inventory" {
  bucket        = local.inventory_bucket
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_versioning" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "inventory" {
  bucket = aws_s3_bucket.inventory.id

  target_bucket = aws_s3_bucket.s3-access-logs.id
  target_prefix = "${local.inventory_bucket}/"
}

resource "aws_s3_bucket_policy" "inventory" {
  bucket = aws_s3_bucket.inventory.id
  policy = data.aws_iam_policy_document.inventory_bucket_policy.json
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
  source   = "github.com/18F/identity-terraform//s3_config?ref=91f5c8a84c664fc5116ef970a5896c2edadff2b1"
  #source = "../s3_config"
  depends_on = [aws_s3_bucket.s3-access-logs]

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = each.key
  region               = var.region
  inventory_bucket_arn = aws_s3_bucket.inventory.arn
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
