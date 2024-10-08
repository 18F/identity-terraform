data "aws_caller_identity" "current" {
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "logging_bucket_id" {
  description = "Id of the S3 bucket used for collecting the S3 access events"
  type        = string
}

# To give ELBs the ability to upload logs to an S3 bucket, we need to create a
# policy that gives permission to a magical AWS account ID to upload logs to our
# bucket, which differs by region.  This table contaings those mappings, and was
# taken from:
# http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
# Also see:
# https://github.com/hashicorp/terraform/pull/3756/files
# For the PR when ELB access logs were added in terraform to see an example of
# the supported test cases for this ELB to S3 logging configuration.
variable "elb_account_ids" {
  type        = map(string)
  description = "Mapping of region to ELB account ID"
  default = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    ca-central-1   = "985666609251"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    eu-west-2      = "652711504416"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-south-1     = "718504428378"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    cn-north-1     = "638102146993"
  }
}

locals {
  logsbucketname = "${var.bucket_name_prefix}.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "logs" {
  bucket        = local.logsbucketname
  force_destroy = var.force_destroy

  tags = {
    Environment = "All"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    # set to AES256 to support NLB - https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html?icmpid=docs_elbv2_console
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  # Allow the ELB account in the current region to put objects.
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "Policy1503676948878",
  "Statement": [
    {
      "Sid": "Stmt1503676946489",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.elb_account_ids[var.region]}:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logsbucketname}/${var.use_prefix_for_permissions ? join(
  "/",
  [
    var.log_prefix,
    "AWSLogs",
    data.aws_caller_identity.current.account_id,
    "*",
  ],
) : "*"}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logsbucketname}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::${local.logsbucketname}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  # In theory we should only put one copy of every file, so I don't think this
  # will increase space, just give us history in case we accidentally
  # delete/modify something.
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  # Lifecycle rules: configure a sliding window for moving logs from standard
  # storage to standard Infrequent Access, then to glacier, then deleting them.
  # The rules will only be enabled if the lifecycle day threshold is set to a
  # positive number.

  rule {
    id     = "log_aging_ia"
    status = var.lifecycle_days_standard_ia > 0 ? "Enabled" : "Disabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = var.lifecycle_days_standard_ia
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "log_aging_glacier"
    status = var.lifecycle_days_glacier > 0 ? "Enabled" : "Disabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = var.lifecycle_days_glacier
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "log_aging_expire"
    status = var.lifecycle_days_expire > 0 ? "Enabled" : "Disabled"

    filter {
      prefix = "/"
    }

    expiration {
      days = var.lifecycle_days_expire
    }
  }
}



module "s3_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=c1ccb75a70894f3c74beed564c0505415d1d1353"
  #source = "../s3_config"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = "elb-logs"
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
}
