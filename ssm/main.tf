data "aws_caller_identity" "current" {
}

# KMS keys
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
      test = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        aws_cloudwatch_log_group.cw_ssm_logs.arn
      ]
    }
  }
}

resource "aws_kms_key" "kms_ssm" {
  description             = "KMSKeyForSSMSessions"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_ssm.json
}

resource "aws_kms_alias" "kms_ssm" {
  name          = "alias/${var.env_name}-kms-ssm"
  target_key_id = aws_kms_key.kms_ssm.key_id
}

# S3 bucket w/KMS key encryption for SSM access logs
resource "aws_s3_bucket" "ssm_logs" {
  bucket = local.s3_bucket_name
  acl    = "private"

  logging {
    target_bucket = local.log_bucket
    target_prefix = "${local.s3_bucket_name}/"
  }

  tags = {
    environment = var.env_name
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kms_ssm.key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire"
    prefix  = "/"
    enabled = true

    transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    expiration {
      days = 2190
    }
    noncurrent_version_expiration {
      days = 2190
    }
  }
}

module "ssm_logs_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = "${var.env_name}-ssm-logs"
  region               = var.region
  inventory_bucket_arn = "arn:aws:s3:::${local.inventory_bucket}"
}

resource "aws_cloudwatch_log_group" "cw_ssm_logs" {
  name              = "aws-ssm-logs-${var.env_name}" #stream name must start with "aws-ssm-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.kms_ssm.arn
}

# Policy and roles to permit SSM access / actions on EC2 instances, and to allow them to send metrics and logs to CloudWatch
data "aws_iam_policy_document" "ssm_access_role_policy" {
  # Basic
  statement {
    sid = "SSMCoreAccess"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "CloudWatchLogsAccessForSSM"
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "*"
    ]
  }
  # S3
  statement {
    sid = "S3ConfigAccessForSSM"
    actions = [
      "s3:GetEncryptionConfiguration"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "S3LoggingAccessForSSM"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.ssm_logs.arn}/*"
    ]
  }
  # KMS
  statement {
    sid = "KMSDecryptionAccess"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      aws_kms_key.kms_ssm.arn
    ]
  }
  
  statement {
    sid = "KMSDataKeyAccess"
    actions = [
      "kms:GenerateDataKey",
    ]
    resources = [
      "*"
    ]
  }
}

# SSM Doc(s)
resource "aws_ssm_document" "ssm_cmd" {
  for_each = var.ssm_doc_map

  name          = "${var.env_name}-ssm-document-${each.key}"
  document_type = "Session"

  version_name = "1.1.0"
  target_type  = "/AWS::EC2::Instance"

  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: ${each.value["description"]}
sessionType: Standard_Stream
inputs:
  s3BucketName: ${aws_s3_bucket.ssm_logs.id}
  s3EncryptionEnabled: true
  cloudWatchLogGroupName: ${aws_cloudwatch_log_group.cw_ssm_logs.name}
  cloudWatchEncryptionEnabled: true
  kmsKeyId: ${aws_kms_key.kms_ssm["sessions"].arn}
  idleSessionTimeout: ${var.session_timeout}
  runAsEnabled: true
  runAsDefaultUser: ''
  shellProfile:
    linux: '${each.value["command"]} ; exit'
  DOC
}
