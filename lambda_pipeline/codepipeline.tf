resource "aws_codepipeline" "lambda" {
  name     = local.build_project_name
  role_arn = aws_iam_role.codepipeline_service.arn

  artifact_store {
    location = var.project_template_s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        PollForSourceChanges = "false"
        S3Bucket             = var.project_template_s3_bucket
        S3ObjectKey          = var.project_template_object_key
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeploywithCodeBuild"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = local.build_project_name
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "codepipeline" {
  name          = local.stack_name
  description   = "Codepipeline artifact update notification"
  event_pattern = <<EOF
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject",
      "CompleteMultipartUpload",
      "CopyObject"
    ],
    "requestParameters": {
      "bucketName": [
        "${var.project_template_s3_bucket}"
      ],
      "key": [
        "${var.project_template_object_key}"
      ]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule     = aws_cloudwatch_event_rule.codepipeline.name
  arn      = aws_codepipeline.lambda.arn
  role_arn = aws_iam_role.cloudwatch_event.arn
}

resource "aws_iam_role" "cloudwatch_event" {
  name_prefix        = "${var.env}-cloudwatch-"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_event_assume_role.json

  tags = {
    environment = var.env
  }
}

data "aws_iam_policy_document" "cloudwatch_event_assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_event_base" {
  name   = "base"
  role   = aws_iam_role.cloudwatch_event.id
  policy = data.aws_iam_policy_document.cloudwatch_event_base.json
}

data "aws_iam_policy_document" "cloudwatch_event_base" {
  statement {
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      aws_codepipeline.lambda.arn
    ]
  }
}

resource "aws_iam_role" "codepipeline_service" {
  name_prefix        = "${var.env}-codepipeline-"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json

  tags = {
    environment = var.env
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline_base" {
  name   = "base"
  role   = aws_iam_role.codepipeline_service.id
  policy = data.aws_iam_policy_document.codepipeline_base.json
}

data "aws_iam_policy_document" "codepipeline_base" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values = [
        "cloudformation.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:SetStackPolicy",
      "cloudformation:ValidateTemplate"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "states:DescribeExecution",
      "states:DescribeStateMachine",
      "states:StartExecution"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "lambda_pipeline_failed" {
  name          = "${var.env}-${var.project_name}-pipeline-failed"
  description   = "CodePipeline execution failed"
  event_pattern = <<EOF
{
    "source": [
        "aws.codepipeline"
    ],
    "detail-type": [
      "CodePipeline Stage Execution State Change"
    ],
    "detail": {
      "state": [
        "FAILED"
      ],
      "pipeline": [
        "${aws_codepipeline.lambda.id}"
      ]
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "sns_slack" {
  rule      = aws_cloudwatch_event_rule.lambda_pipeline_failed.name
  target_id = "SendToSlack"
  arn       = var.pipeline_failure_notification_arn
}
