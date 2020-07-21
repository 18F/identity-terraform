# -- Variables --
variable "bucket_prefix" {
  description = "First substring in S3 bucket name of $bucket_prefix.$bucket_name.$account_id-$region"
  type        = string
  default     = "login-gov"
}

variable "bucket_data" {
  description = "Map of bucket names and their lifecycle rule blocks."
  type        = list(any)
  default     = [
    {
    name = "s3-email",
    acl    = "private",
    policy = "",
    lifecycle_rules = [
      {
        id      = "expireinbound"
        enabled = true
        prefix = "/inbound/"
    
        transition = {
          days          = 30
          storage_class = "STANDARD_IA"
        }
    
        expiration = {
          days = 365
        }
      }
    ],
    public_access_block = true
  },
]
}

variable "log_bucket" {
  description = "Substring for the name of the bucket used for S3 logging."
  type        = string
  default     = "s3-logs"
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
  for_each = var.bucket_list

  bucket = "${var.bucket_prefix}.${each.value.name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = each.value.acl
  policy = each.value.policy

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
    target_prefix = "${var.bucket_prefix}.${each.value.name}.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      id      = lifecycle_rule.value["id"]
      enabled = lifecycle_rule.value["enabled"]
      prefix = lifecycle_rule.value["prefix"]
      transition = lifecycle_rule.value["transition"]
      expiration = lifecycle_rule.value["expiration"]
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

resource "aws_s3_bucket_public_access_block" "block" {
  for_each = compact([ for bucket in var.bucket_data : bucket.public_access_block ? bucket.name : ""])
  
  bucket                  = aws_s3_bucket.bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -- Outputs --
