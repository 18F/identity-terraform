data "aws_iam_policy_document" "kms_ssh_key_pair" {
  statement {
    sid    = "KMSKeyAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:CancelKeyDeletion",
      "kms:Create*",
      "kms:Decrypt",
      "kms:Delete*",
      "kms:Describe*",
      "kms:Disable*",
      "kms:Enable*",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:Get*",
      "kms:List*",
      "kms:Put*",
      "kms:ReEncrypt*",
      "kms:Revoke*",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:Update*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "KMSGrantsAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true",
      ]
    }
  }
}

resource "aws_kms_key" "ssh_key_pair" {
  description             = "Encrypts SSH key for ${var.git2s3_project_name} to access GitHub"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_ssh_key_pair.json
}

resource "aws_kms_alias" "ssh_key_pair" {
  name          = "alias/${local.ssh_key_path}-encrypt"
  target_key_id = aws_kms_key.ssh_key_pair.key_id
}
