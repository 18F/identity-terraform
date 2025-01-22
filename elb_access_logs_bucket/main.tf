data "aws_caller_identity" "current" {
}

locals {
  logsbucketname = "${var.bucket_name_prefix}.elb-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_prefix_path = join("/",
    [
      var.log_prefix,
      "AWSLogs",
      data.aws_caller_identity.current.account_id,
      "*",
    ],
  )
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
  policy = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "Stmt1503676946489"
    effect = "Allow"

    resources = [
      "${aws_s3_bucket.logs.arn}/${var.use_prefix_for_permissions ? local.logs_prefix_path : "*"}"
    ]

    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.elb_account_ids[var.region]}:root"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["${aws_s3_bucket.logs.arn}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [aws_s3_bucket.logs.arn]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid    = "DenyNonHTTPS"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }

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
