# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "lambda_default_access_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "lambda" {
  depends_on  = [null_resource.source_hash_check]
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${local.zip_file}.zip"
}

# -- Resources --

resource "aws_iam_role" "lambda_access_role" {
  count = var.external_role_arn == "" ? 1 : 0

  name               = "${var.function_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_default_access_policy.json
}

resource "null_resource" "source_hash_check" {
  triggers = {
    source_hash = filebase64sha256("${var.source_dir}/${var.source_code_filename}")
  }
}

resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.lambda.output_path
  function_name = var.function_name
  role          = var.external_role_arn == "" ? aws_iam_role.lambda_access_role[0].arn : var.external_role_arn
  description   = var.description
  handler       = var.handler

  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size      = var.memory_size
  runtime          = var.runtime
  timeout          = var.timeout

  dynamic "environment" {
    for_each = local.environment_map
    content {
      variables = environment.value
    }
  }
}

resource "aws_lambda_permission" "invoke" {
  count = length(var.permission_principal)

  statement_id  = local.statement_id
  function_name = aws_lambda_function.lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = var.permission_principal[count.index]
  source_arn    = var.permission_source_arn
}
