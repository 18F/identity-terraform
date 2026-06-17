data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "s3_require_secure_connections" {
  source_policy_documents = length(var.bucket_policy_doc) > 0 ? [var.bucket_policy_doc] : []
  statement {
    sid    = "S3DenyNonSecureConnections"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

data "aws_iam_policy_document" "kms" {
  source_policy_documents = length(var.key_policy_doc) > 0 ? [var.key_policy_doc] : []
  statement {
    sid    = "KMSRootAdminAndIAM"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}
