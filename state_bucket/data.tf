locals {

  tf-state_bucket_arn = var.remote_state_enabled == 1 ? [data.aws_s3_bucket.tf-state[0].arn] : []

  buckets = setunion(
    [
      aws_s3_bucket.inventory.arn,
      aws_s3_bucket.s3-access-logs.arn,
    ], local.tf-state_bucket_arn
  )
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_reject_non_secure_operations[aws_s3_bucket.inventory.arn].json
  ]
  statement {
    sid = "AllowInventoryBucketAccess"
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

data "aws_iam_policy_document" "s3_reject_non_secure_operations" {
  for_each = local.buckets
  statement {
    sid = "S3DenyNonSecureConnections"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      each.key,
      "${each.key}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}
