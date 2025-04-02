data "aws_iam_policy_document" "codebuild_base" {
  statement {
    sid    = "CodeBuildLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [join(":", [
      "arn:aws:logs",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      "log-group:/aws/codebuild/*"
    ])]
  }

  statement {
    sid    = "S3KeyBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.secrets_bucket}",
      "arn:aws:s3:::${var.secrets_bucket}/*"
    ]
  }

  statement {
    sid    = "S3OutputBucketAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.codebuild_output.arn,
      "${aws_s3_bucket.codebuild_output.arn}/*"
    ]
  }

  statement {
    sid    = "KMSKeyForSSHAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.lambda_sshkey.arn
    ]
  }
}

data "aws_iam_policy_document" "codebuild_endpoint" {
  statement {
    sid    = "EC2NetworkAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "EC2CreateNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface"
    ]
    resources = [join(":", [
      "arn:aws:ec2",
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id,
      "network-interface/*"
    ])]
  }
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    sid     = "CodebuildServiceRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_service" {
  name               = "${var.git2s3_project_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "codebuild_base" {
  name   = "${var.git2s3_project_name}-codebuild-base"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_base.json
}

resource "aws_iam_role_policy" "codebuild_endpoint" {
  name   = "${var.git2s3_project_name}-codebuild-endpoint"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_endpoint.json
}

resource "aws_cloudwatch_log_group" "codebuild_git2s3" {
  name              = "/aws/codebuild/${var.git2s3_project_name}"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.prevent_tf_log_deletion
}

resource "aws_codebuild_project" "git2s3" {
  name           = var.git2s3_project_name
  description    = "Pull code from GitHub, ZIP it up, and push to S3"
  service_role   = aws_iam_role.codebuild_service.arn
  build_timeout  = 14
  queued_timeout = 60

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type            = "NO_SOURCE"
    git_clone_depth = 0
    buildspec       = "${path.module}/buildspec-git2s3.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_git2s3.name
    }
  }
}

