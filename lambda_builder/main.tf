# -- Variables --

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function"
  type = number
  default     = 90
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type = number
  default     = 128
}

variable "lambda_package" {
  description = "Lambda source package file location"
  type = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type = string
}

variable "lambda_vars" {
  description = "Map of key-value pairs for Lambda function, in the form variable:value"
  type = string
}

variable "lambda_description" {
  description = "Lambda description"
  type = string
}

# -- Data Sources --

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    sid    = "cloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.lambda.arn
    ]
  }
}

# -- Resources --

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "lambda" {
  filename         = var.lambda_package
  function_name    = var.lambda_name
  description      = var.lambda_description
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = filebase64sha256("${var.lambda_package}")

  environment {
    variables = var.lambda_vars
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lamba_cloudwatch" {
  name   = "cloudwatch"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json
}
