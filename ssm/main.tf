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
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        for logname in ["sessions", "cmds"] : join(":",
          [
            "arn:aws:logs",
            var.region,
            data.aws_caller_identity.current.account_id,
            "log-group",
            "aws-ssm-${logname}-${var.env_name}"
          ]
        )
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

  tags = {
    environment = var.env_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_ssm.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  target_bucket = local.log_bucket
  target_prefix = "${local.s3_bucket_name}/"
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.ssm_logs]
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  rule {
    id     = "expire"
    status = "Enabled"

    filter {
      prefix = "/"
    }

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
      noncurrent_days = 2190
    }
  }
}

module "ssm_logs_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=91f5c8a84c664fc5116ef970a5896c2edadff2b1"
  #source = "../s3_config"

  bucket_name_override = aws_s3_bucket.ssm_logs.id
  inventory_bucket_arn = "arn:aws:s3:::${local.inventory_bucket}"
  depends_on           = [aws_s3_bucket.ssm_logs]
}

resource "aws_cloudwatch_log_group" "ssm_session_logs" {
  name              = "aws-ssm-sessions-${var.env_name}" #stream name must start with "aws-ssm-logs"
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
      "ssmmessages:OpenDataChannel",
      "ec2messages:GetMessages",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:SendReply",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations"
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
      "kms:GenerateDataKey",
    ]
    resources = [
      aws_kms_key.kms_ssm.arn
    ]
  }
}

# SSM Session Docs
resource "aws_ssm_document" "ssm_session" {
  for_each = var.ssm_doc_map
  lifecycle { create_before_destroy = false }
  name            = "${var.env_name}-ssm-document-${each.key}"
  document_type   = "Session"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: ${each.value["description"]}
sessionType: Standard_Stream
inputs:
  %{if each.value["logging"]}s3BucketName: "${aws_s3_bucket.ssm_logs.id}"
  s3EncryptionEnabled: true
  cloudWatchLogGroupName: "${aws_cloudwatch_log_group.ssm_session_logs.name}"
  cloudWatchEncryptionEnabled: true
  cloudWatchStreamingEnabled: true%{else}s3EncryptionEnabled: false
  cloudWatchEncryptionEnabled: false%{endif}
  kmsKeyId: ${aws_kms_key.kms_ssm.arn}
  idleSessionTimeout: ${var.session_timeout}
  runAsEnabled: true
  runAsDefaultUser: ''
  shellProfile:
    linux: 'trap "exit 0" INT TERM; ${each.value["command"]} ; exit'
  DOC
}

# SSM Command Docs
resource "aws_ssm_document" "ssm_cmd" {
  for_each = var.ssm_cmd_doc_map
  lifecycle { create_before_destroy = false }

  name            = "${var.env_name}-ssm-cmd-${each.key}"
  document_type   = "Command"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: "2.2"
description: "${each.value["description"]}"
parameters:
  %{for ssm_parameter in each.value["parameters"]}
  ${ssm_parameter.name}:
    type: ${ssm_parameter.type}
    default: ${ssm_parameter.default}
    description: ${ssm_parameter.description}
  %{endfor}
mainSteps:
- action: "aws:runShellScript"
  name: "block1"
  inputs:
    runCommand:
  %{for ssm_cmd in each.value["command"]~}
  - ${ssm_cmd}
  %{endfor}
  DOC
}

# SSM InteractiveCommands Session Docs
resource "aws_ssm_document" "ssm_interactive_cmd" {
  for_each = var.ssm_interactive_cmd_map
  lifecycle { create_before_destroy = false }
  name            = "${var.env_name}-ssm-document-${each.key}"
  document_type   = "Session"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: ${each.value["description"]}
sessionType: InteractiveCommands
inputs:
  s3EncryptionEnabled: false
  cloudWatchEncryptionEnabled: false
  kmsKeyId: ${aws_kms_key.kms_ssm.arn}
  idleSessionTimeout: ${var.session_timeout}
parameters:
  %{for ssm_parameter in each.value["parameters"]}
  ${ssm_parameter.name}:
    type: ${ssm_parameter.type}
    default: ${ssm_parameter.default}
    description: ${ssm_parameter.description}
    allowedPattern: ${ssm_parameter.pattern}
  %{endfor}
properties:
  linux:
    %{for ssm_cmd in each.value["command"]}commands: "${ssm_cmd}"%{endfor}
    runAsElevated: true
  DOC
}

# log when SSM commands are used, even if session data is not
resource "aws_cloudwatch_event_rule" "ssm_cmd" {
  for_each = local.all_docs_and_cmds

  name        = "${var.env_name}-ssm-cmd-${each.key}"
  description = "Capture when SSM command '${each.key}' used in ${var.env_name}"

  event_pattern = <<PATTERN
{
    "source": [
        "aws.ssm"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
            "ssm.amazonaws.com"
        ],
        "requestParameters": {
            "documentName": [
              "${var.env_name}-ssm-document-${each.key}"
            ]
        },
        "eventName": [
            "StartSession",
            "ResumeSession",
            "TerminateSession"
        ]
    }
}
PATTERN
}

resource "aws_cloudwatch_log_group" "ssm_cmd_logs" {
  name              = "aws-ssm-cmds-${var.env_name}" #stream name must start with "aws-ssm-cmds"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.kms_ssm.arn
}

resource "aws_cloudwatch_event_target" "ssm_cmds" {
  for_each = local.all_docs_and_cmds

  rule      = aws_cloudwatch_event_rule.ssm_cmd[each.key].name
  target_id = "${var.env_name}_SSMCmd_${each.key}"
  arn       = aws_cloudwatch_log_group.ssm_cmd_logs.arn
}

