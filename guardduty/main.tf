locals {
  gd_perm_conditions = [
    {
      "variable" = "aws:SourceAccount",
      "values"   = [data.aws_caller_identity.current.account_id]
    },
    {
      "variable" = "aws:SourceArn",
      "values"   = [aws_guardduty_detector.main.arn]
    }
  ]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  region = var.region
}

resource "aws_guardduty_detector" "main" {
  region = data.aws_region.current
  enable = true

  finding_publishing_frequency = var.finding_freq
}

resource "aws_guardduty_detector_feature" "main" {
  for_each = var.enabled_features

  name        = each.key
  detector_id = aws_guardduty_detector.main.id
  region = data.aws_region.current
  status      = "ENABLED"

  dynamic "additional_configuration" {
    for_each = each.value
    content {
      name   = additional_configuration.value
      status = "ENABLED"
    }
  }
}

resource "aws_guardduty_publishing_destination" "s3" {
  region = data.aws_region.current

  detector_id      = aws_guardduty_detector.main.id
  destination_arn  = module.s3_bucket.bucket_arn
  kms_key_arn      = aws_kms_key.guardduty.arn
  destination_type = "S3"

  depends_on = [
    module.s3_bucket.bucket_policy
  ]
}
