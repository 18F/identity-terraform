resource "aws_kms_key" "cloudtrail" {
  description = "Symmetric encryption key used by CloudTrail and its S3 bucket for event/log encryption"

  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = var.kms_enable_rotation
  rotation_period_in_days = var.kms_rotation_period
  multi_region            = var.is_multi_region_trail
}

resource "aws_kms_key_policy" "cloudtrail" {
  key_id = aws_kms_key.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_kms.json
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.trail_name}"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_kms_replica_key" "cloudtrail" {
  for_each = var.is_multi_region_trail ? setsubtract(var.kms_regions, [data.aws_region.current.region]) : []

  region                  = each.key
  description             = "${each.key} replica of multi-region KMS key used by CloudTrail"
  deletion_window_in_days = var.kms_deletion_window
  primary_key_arn         = aws_kms_key.cloudtrail.arn
}

resource "aws_kms_alias" "cloudtrail_replica" {
  for_each = var.is_multi_region_trail ? setsubtract(var.kms_regions, [data.aws_region.current.region]) : []

  name          = "alias/sns-kms"
  region        = each.key
  target_key_id = aws_kms_replica_key.cloudtrail[each.key].key_id
}

data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    sid    = "AllowAccountPermissions"
    effect = "Allow"
    actions = [
      "kms:*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowCloudTrailEncryption"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudtrail.main.arn
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailDescribeKey"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowCloudTrailDecryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
      ]
    }
  }
}
