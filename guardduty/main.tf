data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


locals {
  partition = contains(["us-gov-east-1", "us-gov-west-1"], data.aws_region.current.region) ? "aws-us-gov" : "aws"
}
# GuardDuty

resource "aws_guardduty_detector" "main" {
  enable = true

  finding_publishing_frequency = var.finding_freq
}

resource "aws_guardduty_detector_feature" "main" {
  for_each = setsubtract(
    var.enabled_features,
    distinct(flatten([keys(local.features_additional), values(local.features_additional)]))
  )

  detector_id = aws_guardduty_detector.main.id
  name        = each.key
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "additional" {
  for_each = setintersection(var.enabled_features, keys(local.features_additional))

  detector_id = aws_guardduty_detector.main.id
  name        = each.key
  status      = "ENABLED"

  dynamic "additional_configuration" {
    for_each = setintersection(var.enabled_features, local.features_additional[each.key])
    content {
      name   = additional_configuration.value
      status = "ENABLED"
    }
  }
}

resource "aws_guardduty_publishing_destination" "s3" {
  detector_id      = aws_guardduty_detector.main.id
  destination_arn  = aws_s3_bucket.guardduty.arn
  kms_key_arn      = aws_kms_key.guardduty.arn
  destination_type = "S3"

  depends_on = [
    aws_s3_bucket_policy.guardduty
  ]
}

# KMS

data "aws_iam_policy_document" "guardduty_kms" {
  statement {
    sid    = "AllowKMSEncryption"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      "arn:${local.partition}:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = local.gd_perm_conditions
      content {
        test     = "StringEquals"
        variable = condition.value["variable"]
        values   = condition.value["values"]
      }
    }
  }

  statement {
    sid    = "KMSRootIAMAllow"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${local.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
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

resource "aws_kms_key" "guardduty" {
  description             = "KMS Key for GuardDuty publishing"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.guardduty_kms.json
}

resource "aws_kms_alias" "guardduty" {
  name          = "alias/guardduty-kms"
  target_key_id = aws_kms_key.guardduty.key_id
}

# S3

data "aws_iam_policy_document" "guardduty_s3" {
  statement {
    sid    = "AllowGDGetBucketLocation"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.guardduty.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = local.gd_perm_conditions
      content {
        test     = "StringEquals"
        variable = condition.value["variable"]
        values   = condition.value["values"]
      }
    }
  }

  statement {
    sid    = "AllowGDPutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.guardduty.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = local.gd_perm_conditions
      content {
        test     = "StringEquals"
        variable = condition.value["variable"]
        values   = condition.value["values"]
      }
    }
  }

  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.guardduty.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.guardduty.arn]
    }
  }

  statement {
    sid    = "DenyNonHTTPS"
    effect = "Deny"
    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.guardduty.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "guardduty" {
  bucket = var.bucket_name_override == "" ? join(".", [
    "${var.bucket_name_prefix}.${var.bucket_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ]) : var.bucket_name_override
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.guardduty]
}

resource "aws_s3_bucket_policy" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id
  policy = data.aws_iam_policy_document.guardduty_s3.json
}

resource "aws_s3_bucket_logging" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id

  target_bucket = local.log_bucket
  target_prefix = "${aws_s3_bucket.guardduty.id}/"
}

resource "aws_s3_bucket_versioning" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty" {
  bucket = aws_s3_bucket.guardduty.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.guardduty.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "guardduty" {
  bucket = aws_s3_bucket.guardduty.id

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "expire"
    status = "Enabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 0
      storage_class   = "INTELLIGENT_TIERING"
    }

    expiration {
      days = 2190
    }

    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "guardduty_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=91f5c8a84c664fc5116ef970a5896c2edadff2b1"
  #source = "../s3_config"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = "guardduty"
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

# CloudWatch Event Logging

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = var.cloudwatch_name
  description = "Send GuardDuty findings to CW Log Groups"
  tags = {
    "Name" = var.cloudwatch_name
  }

  event_pattern = <<EOM
{
  "source" : [
    "aws.guardduty"
  ],
  "detail-type" : [
    "GuardDuty Finding"
  ]
}
EOM
}

resource "aws_cloudwatch_log_group" "guardduty_findings" {
  name              = var.log_group_id
  retention_in_days = 365
  tags = {
    "Name" = var.cloudwatch_name
  }
}

resource "aws_cloudwatch_event_target" "guardduty_findings" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = var.event_target_id
  arn       = aws_cloudwatch_log_group.guardduty_findings.arn
}

data "aws_iam_policy_document" "delivery_events_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "arn:${local.partition}:logs:*:*:*"
    ]
    principals {
      identifiers = [
        "delivery.logs.amazonaws.com",
        "events.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "delivery_events_logs" {
  policy_document = data.aws_iam_policy_document.delivery_events_logs.json
  policy_name     = var.publishing_policy_name
}
