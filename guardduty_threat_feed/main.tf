##### GuardDuty Detector #####

resource "aws_guardduty_detector" "gd" {
  enable = true

  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }
    kubernetes {
      audit_logs {
        enable = var.enable_k8s_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }
}

##### GuardDuty Findings (CloudWatch log group + triggers + related resources) #####

# CloudWatch

resource "aws_cloudwatch_log_group" "gd_findings" {
  name              = "/aws/events/gdfindings"
  retention_in_days = 365
  tags = {
    "Name" = "GuardDuty findings"
  }
}

resource "aws_cloudwatch_event_rule" "gd_findings" {
  name        = "GuardDutyFindings"
  description = "Send GuardDuty findings to CW Log Groups"
  tags = {
    "Name" = "GuardDuty Findings"
  }

  event_pattern = jsonencode(
    {
      "source" : [
        "aws.guardduty"
      ],
      "detail-type" : [
        "GuardDuty Finding"
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "cw_target_to_cw_logs" {
  rule      = aws_cloudwatch_event_rule.gd_findings.name
  target_id = "SendGDFindingsToCWLogGroup"
  arn       = aws_cloudwatch_log_group.gd_findings.arn
}

# IAM

data "aws_iam_policy_document" "gd_findings_logs_access" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/events/gdfindings"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com", "events.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "gd_findings_logs_access" {
  policy_document = data.aws_iam_policy_document.gd_findings_logs_access.json
  policy_name     = "gd_findings_logs_access"
  lifecycle {
    create_before_destroy = true
  }
}

##### GuardDuty Threat Feed (Lamda function + related resources) #####

# IAM

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "lambda_assumerole" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "gd_access" {
  statement {
    sid    = "${local.guardduty_feedname_iam}GuardDutyAccess"
    effect = "Allow"
    actions = [
      "guardduty:ListDetectors",
      "guardduty:CreateThreatIntelSet",
      "guardduty:GetThreatIntelSet",
      "guardduty:ListThreatIntelSets",
      "guardduty:UpdateThreatIntelSet"
    ]
    resources = [
      join(":", [
        "arn:aws:guardduty:${var.region}",
        data.aws_caller_identity.current.account_id,
        "detector/*"
      ])
    ]
  }

  statement {
    sid    = "${local.guardduty_feedname_iam}IAMAccess"
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy"
    ]
    resources = [
      join("", [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}/role/",
        "aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
      ])
    ]
  }

  statement {
    sid    = "${local.guardduty_feedname_iam}S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.gd_s3_bucket.id}"
    ]
  }

  statement {
    sid    = "${local.guardduty_feedname_iam}S3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.gd_s3_bucket.id}/*"
    ]
  }

  statement {
    sid    = "${local.guardduty_feedname_iam}SSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.key["public"].arn,
      aws_ssm_parameter.key["private"].arn
    ]
  }
}

resource "aws_iam_policy" "gd_access" {
  name        = "${var.guardduty_threat_feed_name}-lambda-policy"
  description = "Policy for ${var.guardduty_threat_feed_name}-lambda access"
  policy      = data.aws_iam_policy_document.gd_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.gd_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "gd_access" {
  role       = aws_iam_role.gd_lambda.name
  policy_arn = aws_iam_policy.gd_access.arn
}

resource "aws_iam_role" "gd_lambda" {
  name               = "${var.guardduty_threat_feed_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assumerole.json
}


# S3

resource "aws_s3_bucket" "gd_s3_bucket" {
  bucket = local.gd_s3_bucket
  tags = {
    feed = var.guardduty_threat_feed_name
  }
}

resource "aws_s3_bucket_acl" "gd_s3_bucket" {
  bucket = aws_s3_bucket.gd_s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "gd_s3_bucket" {
  bucket = aws_s3_bucket.gd_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gd_s3_bucket" {
  bucket = aws_s3_bucket.gd_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "gd_s3_bucket" {
  bucket = aws_s3_bucket.gd_s3_bucket.id

  target_bucket = var.logs_bucket
  target_prefix = "${local.gd_s3_bucket}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "gd_s3_bucket" {
  bucket = aws_s3_bucket.gd_s3_bucket.id

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

module "gd_s3_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  bucket_name_override = aws_s3_bucket.gd_s3_bucket.id
  inventory_bucket_arn = var.inventory_bucket_arn
}

# CloudWatch

resource "aws_cloudwatch_event_rule" "auto_update" {
  name                = "${var.guardduty_threat_feed_name}-auto-update"
  description         = "Auto-update GuardDuty threat feed every ${var.guardduty_frequency} days"
  schedule_expression = "rate(${var.guardduty_frequency} days)"
}

resource "aws_cloudwatch_event_target" "auto_update" {
  rule      = aws_cloudwatch_event_rule.auto_update.name
  target_id = aws_cloudwatch_event_rule.auto_update.name
  arn       = aws_lambda_function.lambda.arn
}

# SSM parameters (public/private keys)

resource "aws_ssm_parameter" "key" {
  for_each = toset(["public", "private"])

  name        = "${var.guardduty_threat_feed_name}-${each.key}-key"
  description = "Guard Duty Threat Feed 3rd party ${each.key} key"
  type        = "SecureString"
  value       = "${each.key}-test" # manually update after deploying
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

# Lambda function

module "lambda_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  source_code_filename = "guardduty_threat_feed.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "guardduty_threat_feed.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = module.lambda_code.zip_output_path
  function_name = "${var.guardduty_threat_feed_name}-function"
  role          = aws_iam_role.gd_lambda.arn
  description   = "GuardDuty Threat Feed Function"
  handler       = "guardduty_threat_feed.lambda_handler"

  source_code_hash = module.lambda_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = "python3.9"
  timeout          = "300"

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      DAYS_REQUESTED = var.guardduty_days_requested,
      PUBLIC_KEY     = aws_ssm_parameter.key["public"].name,
      PRIVATE_KEY    = aws_ssm_parameter.key["private"].name,
      OUTPUT_BUCKET  = aws_s3_bucket.gd_s3_bucket.id
    }
  }

  depends_on = [module.lambda_code.resource_check]
}

resource "aws_lambda_permission" "guardduty_threat_feed_lambda_permission" {
  statement_id  = "${var.guardduty_threat_feed_name}-lambda-permission"
  function_name = aws_lambda_function.lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auto_update.arn
}