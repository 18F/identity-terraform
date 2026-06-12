data "aws_iam_policy_document" "kms_ssm" {
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

  statement {
    sid    = "KMSCloudWatchEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        for logname in toset(flatten([local.invocation_log_list, local.output_log_list])) : join(":",
          [
            "arn:aws:logs",
            var.region,
            data.aws_caller_identity.current.account_id,
            "log-group",
            "/aws/ssm/${var.env_name}/${logname}"
          ]
        )
      ]
    }
  }
}

resource "aws_kms_key" "ssm" {
  region                  = var.region
  description             = "KMSKeyForSSMSessions"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_ssm.json
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.env_name}-ssm"
  region        = var.region
  target_key_id = aws_kms_key.ssm.key_id
}

moved {
  from = aws_kms_key.kms_ssm
  to   = aws_kms_key.ssm
}

moved {
  from = aws_kms_alias.kms_ssm
  to   = aws_kms_alias.ssm
}
