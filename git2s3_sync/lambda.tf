data "aws_iam_policy_document" "lambda_access" {
  source_policy_documents = [
    data.aws_iam_policy_document.codebuild_endpoint.json
  ]

  statement {
    sid    = "LambdaCodeBuildAccess"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      aws_codebuild_project.git2s3.arn
    ]
  }
}

module "lambda_git2s3" {
  source = "github.com/18F/identity-terraform//lambda_function?ref=026f69d0a5e2b8af458888a5f21a72d557bbe1fe"
  #source = "../lambda_function"

  region               = data.aws_region.current.name
  function_name        = var.git2s3_project_name
  description          = "Run ${var.git2s3_project_name} CodeBuild project when code is pushed to GitHub"
  source_code_filename = "lambda_function.py"
  source_dir           = "${path.module}/lambda/"
  runtime              = "python3.12"
  timeout              = 900
  memory_size          = 128

  environment_variables = {
    codebuild_project_name = aws_codebuild_project.git2s3.name
  }

  cloudwatch_retention_days = var.cloudwatch_retention_days
  insights_enabled          = false
  alarm_actions             = []

  lambda_iam_policy_document = data.aws_iam_policy_document.lambda_access.json
}
