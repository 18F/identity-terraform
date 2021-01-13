resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.build_project_name}"
  retention_in_days = 365

  tags = {
    environment = var.env
  }
}

resource "aws_codebuild_project" "lambda" {
  name          = local.build_project_name
  description   = var.project_description
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild_service.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    type     = "S3"
    location = "${var.project_template_s3_bucket}/${var.project_template_object_key}"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:4.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.env
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "STACK_NAME"
      value = local.stack_name
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "APPLICATION_PARAM"
      value = var.parameter_application_functions
      type  = "PLAINTEXT"
    }
  }
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  tags = {
    environment = var.env
  }

}

resource "aws_iam_role" "codebuild_service" {
  name_prefix        = "${var.env}-codebuild-"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  tags = {
    environment = var.env
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codebuild_base" {
  name   = "base"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_base.json
}

resource "aws_iam_role_policy" "codebuild_s3" {
  name   = "S3"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_s3.json
}

resource "aws_iam_role_policy" "codebuild_cloudformation" {
  name   = "cloudformation"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_cloudformation.json
}

resource "aws_iam_role_policy" "codebuild_codedeploy" {
  name   = "codedeploy"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_codedeploy.json
}

resource "aws_iam_role_policy" "codebuild_ec2" {
  name   = "ec2"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_ec2.json
}

resource "aws_iam_role_policy" "codebuild_iam" {
  name   = "iam"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_iam.json
}

resource "aws_iam_role_policy" "codebuild_lambda" {
  name   = "lambda"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_lambda.json
}

resource "aws_iam_role_policy" "codebuild_ssm" {
  name   = "ssm"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_ssm.json
}

resource "aws_iam_role_policy" "codebuild_ssm_account" {
  name   = "ssm_account"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_ssm_account.json
}

resource "aws_iam_role_policy" "codebuild_cloudwatch" {
  name   = "cloudwatch"
  role   = aws_iam_role.codebuild_service.id
  policy = data.aws_iam_policy_document.codebuild_cloudwatch.json
}

data "aws_iam_policy_document" "codebuild_base" {
  statement {
    sid    = "base"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.codebuild.arn,
      "${aws_cloudwatch_log_group.codebuild.arn}:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::codepipeline-${var.region}-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:report-group/${local.build_project_name}-*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_s3" {
  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_template_s3_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_template_s3_bucket}/*",
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_artifacts_s3_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_artifacts_s3_bucket}/*",
    ]
  }
  statement {
    sid    = "S3Bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_template_s3_bucket}",
      "arn:${data.aws_partition.current.partition}:s3:::${var.project_artifacts_s3_bucket}",
    ]
  }
}

data "aws_iam_policy_document" "codebuild_cloudformation" {
  statement {
    sid    = "cloudformation"
    effect = "Allow"
    actions = [
      "cloudformation:CreateChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:DescribeStacks",
      "cloudformation:DescribeStackEvents",
      "cloudformation:GetTemplateSummary"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:cloudformation:${var.region}:${data.aws_caller_identity.current.account_id}:stack/${local.stack_name}/*",
      "arn:${data.aws_partition.current.partition}:cloudformation:${var.region}:aws:transform/Serverless-2016-10-31"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_codedeploy" {
  statement {
    sid    = "codedeploy"
    effect = "Allow"
    actions = [
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateApplication",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeployment",
      "codedeploy:DeleteApplication",
      "codedeploy:UpdateDeploymentGroup",
      "codedeploy:CreateDeploymentGroup",
      "codedeploy:DeleteDeploymentGroup",
      "codedeploy:CreateDeployment"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:application:${local.stack_name}*",
      "arn:${data.aws_partition.current.partition}:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${var.env}*/*",
      "arn:${data.aws_partition.current.partition}:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_ec2" {
  statement {
    sid    = "ec2"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:CreateSecurityGroup",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DeleteSecurityGroup",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroupReferences",
      "ec2:DescribeVpcs",
      "ec2:DescribeStaleSecurityGroups",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_iam" {
  statement {
    sid    = "iam"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:UntagRole",
      "iam:TagRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
      "iam:TagUser",
      "iam:UntagUser",
      "iam:PassRole",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.env}*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_lambda" {
  statement {
    sid    = "lambda"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:TagResource",
      "lambda:ListVersionsByFunction",
      "lambda:GetLayerVersion",
      "lambda:GetFunctionConfiguration",
      "lambda:GetLayerVersionPolicy",
      "lambda:UntagResource",
      "lambda:PutFunctionConcurrency",
      "lambda:ListProvisionedConcurrencyConfigs",
      "lambda:ListTags",
      "lambda:DeleteLayerVersion",
      "lambda:PutFunctionEventInvokeConfig",
      "lambda:DeleteFunctionEventInvokeConfig",
      "lambda:DeleteFunction",
      "lambda:GetAlias",
      "lambda:UpdateFunctionEventInvokeConfig",
      "lambda:UpdateEventSourceMapping",
      "lambda:GetEventSourceMapping",
      "lambda:GetFunction",
      "lambda:ListAliases",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode",
      "lambda:ListFunctionEventInvokeConfigs",
      "lambda:GetFunctionConcurrency",
      "lambda:GetFunctionEventInvokeConfig",
      "lambda:DeleteAlias",
      "lambda:PublishVersion",
      "lambda:DeleteFunctionConcurrency",
      "lambda:DeleteEventSourceMapping",
      "lambda:GetPolicy",
      "lambda:CreateAlias"
    ]
    resources = [
      "arn:aws:lambda:${var.region}:580247275435:layer:LambdaInsightsExtension:*", #insights layer from AWS
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.env}*",
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:${var.env}*:*",
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:event-source-mapping:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:GetProvisionedConcurrencyConfig",
      "lambda:PublishLayerVersion",
      "lambda:PutProvisionedConcurrencyConfig",
      "lambda:DeleteProvisionedConcurrencyConfig"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.env}*:*",
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:${var.env}*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:TagResource",
      "lambda:ListVersionsByFunction",
      "lambda:GetLayerVersion",
      "lambda:PublishLayerVersion",
      "lambda:DeleteProvisionedConcurrencyConfig",
      "lambda:GetFunctionConfiguration",
      "lambda:GetLayerVersionPolicy",
      "lambda:UntagResource",
      "lambda:PutFunctionConcurrency",
      "lambda:ListProvisionedConcurrencyConfigs",
      "lambda:GetProvisionedConcurrencyConfig",
      "lambda:ListTags",
      "lambda:DeleteLayerVersion",
      "lambda:PutFunctionEventInvokeConfig",
      "lambda:DeleteFunctionEventInvokeConfig",
      "lambda:DeleteFunction",
      "lambda:GetAlias",
      "lambda:UpdateFunctionEventInvokeConfig",
      "lambda:UpdateEventSourceMapping",
      "lambda:GetEventSourceMapping",
      "lambda:GetFunction",
      "lambda:ListAliases",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode",
      "lambda:ListFunctionEventInvokeConfigs",
      "lambda:GetFunctionConcurrency",
      "lambda:GetFunctionEventInvokeConfig",
      "lambda:PutProvisionedConcurrencyConfig",
      "lambda:DeleteAlias",
      "lambda:PublishVersion",
      "lambda:DeleteFunctionConcurrency",
      "lambda:DeleteEventSourceMapping",
      "lambda:GetPolicy",
      "lambda:CreateAlias"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.env}*",
      "arn:${data.aws_partition.current.partition}:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:event-source-mapping:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:ListFunctions",
      "lambda:ListEventSourceMappings",
      "lambda:ListLayerVersions",
      "lambda:ListLayers",
      "lambda:CreateEventSourceMapping"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_ssm" {
  statement {
    sid    = "ssm"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:RemoveTagsFromResource",
      "ssm:AddTagsToResource",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DeleteParameter"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.env}/**"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_ssm_account" {
  statement {
    sid    = "ssmaccount"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/account/*"
    ]
  }
}

data "aws_iam_policy_document" "codebuild_cloudwatch" {
  statement {
    sid    = "cloudwatch"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:PutCompositeAlarm",
      "cloudwatch:PutInsightRule",
      "cloudwatch:EnableAlarmActions",
      "cloudwatch:DeleteInsightRules",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeInsightRules"
    ]
    resources = [
      "*"
    ]
  }
}