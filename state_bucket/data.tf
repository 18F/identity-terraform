data "aws_caller_identity" "current" {
}

data "aws_s3_bucket" "tf_state" {
  count = var.remote_state_enabled

  bucket = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_iam_policy_document" "s3_reject_non_secure_operations" {
  for_each = toset(compact([
    aws_s3_bucket.inventory.arn,
    aws_s3_bucket.s3_access_logs.arn,
    var.remote_state_enabled == 1 ? data.aws_s3_bucket.tf_state[0].arn : ""
  ]))

  statement {
    sid    = "S3DenyNonSecureConnections"
    effect = "Deny"

    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      each.key,
      "${each.key}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_reject_non_secure_operations[aws_s3_bucket.inventory.arn].json
  ]

  statement {
    sid    = "AllowInventoryBucketAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.inventory.arn}/*"
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
