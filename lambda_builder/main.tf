module "lambda_function" {
  source = "github.com/raymondbutcher/terraform-aws-lambda-builder"

  # Standard aws_lambda_function attributes.
  function_name = "example"
  handler       = "lambda.handler"
  runtime       = "python3.6"
  s3_bucket     = aws_s3_bucket.packages.id
  timeout       = 30

  # Enable build functionality.
  build_mode = "FILENAME"
  source_dir = "${path.module}/src"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}
