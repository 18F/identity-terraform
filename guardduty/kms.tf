data "aws_iam_policy_document" "guardduty_kms" {
  statement {
    sid    = "AllowKMSEncryption"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "Service"
      identifiers = [
        "guardduty.amazonaws.com"
      ]
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
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
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
