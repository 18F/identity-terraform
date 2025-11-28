resource "aws_s3_bucket_policy" "tf_state" {
  count = var.remote_state_enabled

  bucket = data.aws_s3_bucket.tf_state[count.index].id
  policy = data.aws_iam_policy_document.s3_reject_non_secure_operations[data.aws_s3_bucket.tf_state[0].arn].json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  count = var.remote_state_enabled

  bucket = data.aws_s3_bucket.tf_state[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  count = var.remote_state_enabled

  bucket = data.aws_s3_bucket.tf_state[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  count = var.remote_state_enabled

  bucket                                 = data.aws_s3_bucket.tf_state[count.index].id
  transition_default_minimum_object_size = "all_storage_classes_128K"

  rule {
    id     = "TierAndExpire"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "INTELLIGENT_TIERING"
    }

    expiration {
      days = 2557 # 7 years
    }

    noncurrent_version_expiration {
      noncurrent_days = 2557 # 7 years
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "tf_state" {
  count = var.remote_state_enabled

  bucket = data.aws_s3_bucket.tf_state[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tf_state" {
  count = var.remote_state_enabled

  bucket = data.aws_s3_bucket.tf_state[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.tf_state]
}

resource "aws_s3_bucket_logging" "tf_state" {
  count = var.remote_state_enabled

  bucket        = data.aws_s3_bucket.tf_state[count.index].id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "${data.aws_s3_bucket.tf_state[count.index].id}/"
}

module "s3_config" {
  # hacky way to pass in bucket identifiers vs. full IDs, skips resource replacement
  for_each = toset(compact([
    split(".", aws_s3_bucket.s3_access_logs.id)[1],
    var.remote_state_enabled == 1 ? split(".", data.aws_s3_bucket.tf_state[0].id)[1] : ""
  ]))
  source = "github.com/18F/identity-terraform//s3_config?ref=91f5c8a84c664fc5116ef970a5896c2edadff2b1"
  #source = "../s3_config"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = each.key
  region               = var.region
  inventory_bucket_arn = aws_s3_bucket.inventory.arn
}

resource "aws_dynamodb_table" "tf_lock_table" {
  count = var.remote_state_enabled

  name           = var.state_lock_table
  read_capacity  = var.tf_lock_table_read_capacity["minimum"]
  write_capacity = var.tf_lock_table_write_capacity["minimum"]
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  deletion_protection_enabled = var.terraform_lock_deletion_protection

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [read_capacity, write_capacity]
  }
}
