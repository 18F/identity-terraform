data "aws_iam_policy_document" "kms" {
  # Allow root users in
  statement {
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
      "*",
    ]
  }

  # allow an EC2 instance role to use KMS
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    principals {
      type = "AWS"
      identifiers = concat(
        var.ec2_kms_arns
      )
    }
    resources = [
      "*",
    ]
  }

  # Allow CloudWatch Events and SNS Access
  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sns.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_replica_key" "login_dot_gov_keymaker_multi_region_replica" {
  description         = "${var.env_name}-login-dot-gov-keymaker-multi-region"
  policy              = data.aws_iam_policy_document.kms.json
  primary_key_arn     = var.primary_key_arn
}

resource "aws_kms_alias" "login_dot_gov_keymaker_alias" {
  name          = "alias/${var.env_name}-login-dot-gov-keymaker-multi-region"
  target_key_id = aws_kms_replica_key.login_dot_gov_keymaker_multi_region_replica.key_id
}


